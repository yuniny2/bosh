#!/bin/bash

set -eux

export VERSION=100.0.1
export JAVA_HOME="$(/usr/libexec/java_home)/jre"
export PATH=$JAVA_HOME/bin:$PATH


#~/workspace/bosh/src/bosh-dev/assets/sandbox/config_server/credhub/credhub.jar
# http://localhost:8080/uaa
#  ~/workspace/bosh/src/bosh-dev/assets/sandbox/config_server/credhub

#CREDHUB_JAR_PATH=$1
#UAA_URL=$2
#CREDHUB_RESOURCE_DIR=$3

CREDHUB_JAR_PATH=$JAR_FILE
#UAA_URL=$UAA_URL
CREDHUB_RESOURCE_DIR=$ASSETS_DIR

DB=mysql
TRUST_STORE=${CREDHUB_RESOURCE_DIR}/trust_store


credhub_install_dir=/tmp/crehub-release


rm -rf $credhub_install_dir
mkdir $credhub_install_dir

TMP_DIR=$credhub_install_dir

#-Dsun.boot.class.path=/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home/jre/lib/resources.jar:/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home/jre/lib/rt.jar:/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home/jre/lib/sunrsasign.jar:/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home/jre/lib/jsse.jar:/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home/jre/lib/jce.jar:/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home/jre/lib/charsets.jar:/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home/jre/lib/jfr.jar:/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home/jre/classes
# -Djna.boot.library.path=${credhub_install_dir}/packages/credhub/credhub/
#-Dspring.profiles.active=dev,dev-${DB},dev-local-uaa
java_options=(
  -Xmx1024m
  -Dspring.profiles.active=prod
  -Dspring.config.location=${SANDBOX_ROOT}/application.yml
  -Dlog4j.configurationFile=${CREDHUB_RESOURCE_DIR}/log4j2.properties
  -Djava.security.egd=file:/dev/urandom
  -Djava.home=/Library/Java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home/jre
  -Djava.library.path=/Users/pivotal/Library/Java/Extensions:/Library/Java/Extensions:/Network/Library/Java/Extensions:/System/Library/Java/Extensions:/usr/lib/java:
  -Djna.boot.library.path=${JAVA_HOME}/jre/lib
  -Djava.io.tmpdir=$TMP_DIR
  -Djdk.tls.ephemeralDHKeySize=2048
  -Djdk.tls.namedGroups="secp384r1"
  -Djavax.net.ssl.trustStore=trust_store/auth_server_trust_store.jks
  -Djavax.net.ssl.trustStorePassword=changeit
)

uaa_health_check() {
    status=`curl --max-time 5 --connect-timeout 2 -k --silent ${UAA_URL}/healthz`
    if [ $? -ne 0 ]; then
      echo "Could not reach the UAA server"
      exit 1
    fi

    if [ $status != "ok" ]; then
      exit 1
    fi
    echo "Successfully connected to UAA, continuing startup"
}


run_credhub() {
  echo "Starting credhub server"
  echo $PWD

  pushd $CREDHUB_RESOURCE_DIR
    java  ${java_options[*]-} -ea -jar credhub.jar >>/tmp/config.log 2>&1
    #java  ${java_options[*]-} -ea -jar credhub.jar
  popd
}

main() {
  #uaa_health_check
  run_credhub
}
main
