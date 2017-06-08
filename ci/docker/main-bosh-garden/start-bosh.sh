#!/usr/bin/env bash

set -e

mount_btrfs() {
  # Configure cgroup
  mount -tcgroup -odevices cgroup:devices /sys/fs/cgroup
  devices_mount_info=$(cat /proc/self/cgroup | grep devices)
  devices_subdir=$(echo $devices_mount_info | cut -d: -f3)
  echo 'b 7:* rwm' > /sys/fs/cgroup/devices.allow
  echo 'b 7:* rwm' > /sys/fs/cgroup${devices_subdir}/devices.allow

  set +e
  # Setup loop devices
  for i in {0..256}
  do
    mknod -m777 /dev/loop$i b 7 $i
  done
  set -e

  # Make BTRFS volume
  truncate -s 8G /btrfs_volume
  mkfs.btrfs /btrfs_volume

  # Mount BTRFS
  mkdir /mnt/btrfs
  mount -t btrfs -o user_subvol_rm_allowed,rw /btrfs_volume /mnt/btrfs
  chmod 777 -R /mnt/btrfs
  btrfs quota enable /mnt/btrfs
}

init_grootfs_storage() {
  /opt/garden/bin/grootfs --config /opt/garden/grootfs-unprivileged.yml init-store \
    --uid-mapping 0:4294967294:1 --uid-mapping 1:1:4294967293 \
    --gid-mapping 0:4294967294:1 --gid-mapping 1:1:4294967293
  /opt/garden/bin/grootfs --config /opt/garden/grootfs-privileged.yml init-store
}

start_garden() {
  echo "nameserver 8.8.8.8" > /etc/resolv.conf

  # check for /proc/sys being mounted readonly, as systemd does
  if ! grep -qs '/sys' /proc/mounts; then
    mount -t sysfs sysfs /sys
  fi

  mount_btrfs

  init_grootfs_storage

  local mtu=$(cat /sys/class/net/$(ip route get 8.8.8.8|awk '{ print $5 }')/mtu)
  local tmpdir=$(mktemp -d)

  local depot_path=$tmpdir/depot

  mkdir -p $depot_path

  export TMPDIR=$tmpdir
  export TEMP=$tmpdir
  export TMP=$tmpdir

  /opt/garden/bin/gdn server \
    --allow-host-access \
    --depot $depot_path \
    --bind-ip 0.0.0.0 --bind-port 7777 \
    --mtu $mtu \
    --image-plugin /opt/garden/bin/grootfs \
    --image-plugin-extra-arg='--config' \
    --image-plugin-extra-arg='/opt/garden/grootfs-unprivileged.yml' \
    --privileged-image-plugin=/opt/garden/bin/grootfs \
    --privileged-image-plugin-extra-arg='--config' \
    --privileged-image-plugin-extra-arg='/opt/garden/grootfs-privileged.yml' \
    &

    curl -o /usr/local/bin/gaol -L https://github.com/contraband/gaol/releases/download/2016-8-22/gaol_linux
    chmod +x /usr/local/bin/gaol
}

function main() {
  source /etc/profile.d/chruby.sh
  chruby 2.3.1

  export OUTER_CONTAINER_IP=$(ruby -rsocket -e 'puts Socket.ip_address_list
                          .reject { |addr| !addr.ip? || addr.ipv4_loopback? || addr.ipv6? }
                          .map { |addr| addr.ip_address }')

  export GARDEN_HOST=${OUTER_CONTAINER_IP}

  start_garden

  local local_bosh_dir
  local_bosh_dir="/tmp/local-bosh/director"

  # docker network create -d bridge --subnet=10.245.0.0/16 director_network

  pushd /usr/local/bosh-deployment > /dev/null
      export BOSH_DIRECTOR_IP="10.245.0.3"
      export BOSH_ENVIRONMENT="warden-director"

      mkdir -p ${local_bosh_dir}

      command bosh int bosh.yml \
        -o warden/cpi.yml \
        -o jumpbox-user.yml \
        -o bosh-lite.yml \
        -o bosh-lite-runc.yml \
        -v director_name=warden \
        -v internal_cidr=10.245.0.0/16 \
        -v internal_gw=10.245.0.1 \
        -v internal_ip="${BOSH_DIRECTOR_IP}" \
        -v garden_host="${GARDEN_HOST}" \
        -v network=director_network \
        ${@} > "${local_bosh_dir}/bosh-director.yml"

      command bosh create-env "${local_bosh_dir}/bosh-director.yml" \
              --vars-store="${local_bosh_dir}/creds.yml" \
              --state="${local_bosh_dir}/state.json"

      bosh int "${local_bosh_dir}/creds.yml" --path /director_ssl/ca > "${local_bosh_dir}/ca.crt"
      bosh -e "${BOSH_DIRECTOR_IP}" --ca-cert "${local_bosh_dir}/ca.crt" alias-env "${BOSH_ENVIRONMENT}"

      cat <<EOF > "${local_bosh_dir}/env"
      export BOSH_ENVIRONMENT="${BOSH_ENVIRONMENT}"
      export BOSH_CLIENT=admin
      export BOSH_CLIENT_SECRET=`bosh int "${local_bosh_dir}/creds.yml" --path /admin_password`
      export BOSH_CA_CERT="${local_bosh_dir}/ca.crt"

EOF
      source "${local_bosh_dir}/env"

      bosh -n update-cloud-config warden/cloud-config.yml

  popd > /dev/null
}

main $@
