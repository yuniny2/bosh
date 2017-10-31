#!/usr/bin/env bash

[ -z $PG_DIR ] && export PG_DIR=/tmp/postgres-integration
export PGDATA_DIR=$PG_DIR/data
export PGDATA_SSL_DIR=${PGDATA_DIR}_ssl
export PGLOG_DIR=${PG_DIR}/log
export LOG_FILE=$PGLOG_DIR/server.log
export SSL_LOG_FILE=${PGLOG_DIR}/server_ssl.log

export POSTGRES_PORT=55000
export POSTGRES_SSL_PORT=56000

start_postgres() {
  mkdir -p $PG_DIR
  mkdir -p $PGDATA_DIR
  mkdir -p $PGDATA_SSL_DIR
  mkdir -p $PGLOG_DIR

  initdb -D $PGDATA_DIR -U postgres
  initdb -D $PGDATA_SSL_DIR -U postgres

  pg_ctl -D $PGDATA_DIR start -l $LOG_FILE -o "-p ${POSTGRES_PORT} -N 400"

  SERVER_CERT_PATH=$SOURCE_ROOT/src/bosh-dev/assets/sandbox/database/postgres_server
  PGSSLCERT=$SERVER_CERT_PATH/certificate.pem
  PGSSLKEY=$SERVER_CERT_PATH/private_key
  cp $PGSSLCERT $PGDATA_SSL_DIR/server.crt
  cp $PGSSLKEY $PGDATA_SSL_DIR/server.key
  chmod 600 $PGDATA_SSL_DIR/server.crt $PGDATA_SSL_DIR/server.key

  pg_ctl -D $PGDATA_SSL_DIR start -l $SSL_LOG_FILE -o "-l -p ${POSTGRES_SSL_PORT} -N 400"
}

stop_postgres() {
  pg_ctl -D $PGDATA_DIR stop
  pg_ctl -D $PGDATA_SSL_DIR stop

  rm -rf $PGDATA_DIR
  rm -rf $PGDATA_SSL_DIR
}

alias pspg='ps ax | grep postgres'
alias start_pg_local="SOURCE_ROOT=$(pwd) start_postgres"
