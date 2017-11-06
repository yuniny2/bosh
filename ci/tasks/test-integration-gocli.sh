#!/usr/bin/env bash

set -e

source bosh-src/ci/tasks/utils.sh

check_param RUBY_VERSION
check_param DB

echo "Starting $DB..."
case "$DB" in
  mysql)
    mv /var/lib/mysql /var/lib/mysql-src
    mkdir /var/lib/mysql
    mount -t tmpfs -o size=512M tmpfs /var/lib/mysql
    mv /var/lib/mysql-src/* /var/lib/mysql/

    sudo service mysql start
    ;;
  postgresql)
    export PG_DIR=/tmp/postgres
    mkdir $PG_DIR
    mount -t tmpfs -o size=512M tmpfs $PG_DIR
    mkdir /tmp/postgres/data
    chown postgres:postgres /tmp/postgres/data

    su postgres -c "
      export PG_DIR=${PG_DIR}
      export PATH=/usr/lib/postgresql/9.4/bin:\$PATH
      source ./bosh-src/dev/postgres_utils.sh

      SOURCE_ROOT=\$(pwd)/bosh-src start_postgres
    "
    ;;
  *)
    echo "Usage: DB={mysql|postgresql} $0 {commands}"
    exit 1
esac

mv ./bosh-cli/*bosh-cli-*-linux-amd64 /usr/local/bin/bosh
chmod +x /usr/local/bin/bosh

source /etc/profile.d/chruby.sh
chruby $RUBY_VERSION

agent_path=bosh-src/src/go/src/github.com/cloudfoundry/
mkdir -p $agent_path
cp -r bosh-agent $agent_path

cd bosh-src/src

print_git_state

bundle install --local

bundle exec rake --trace spec:integration_gocli
