#!/usr/bin/env bash

set -eu

DIRNAME=$(dirname "$0")

KEYSTORE_PASSWORD=changeit

KEY_STORE=key_store.jks
AUTH_SERVER_TRUST_STORE=auth_server_trust_store.jks
UAA_CA=${DIRNAME}/../../ca/certs/rootCA.pem

clean() {
    echo "Removing any existing key stores and certs..."
    rm -f "${DIRNAME}"/*.jks "${DIRNAME}"/*.csr "${DIRNAME}"/*.srl "${DIRNAME}"/*.pem
}

setup_tls_key_store() {
    echo "Generating a key store for the certificate the server presents during TLS"
    # generate keypair for the server cert
    openssl genrsa -out server.key 2048


    echo "Create CSR for the server cert"
    openssl req -new -sha256 -key server.key -subj "/CN=localhost" -out server.csr

    echo "Test run"
    openssl req -text -noout -in server.csr

    echo "Generate server certificate signed by our CA"
    openssl x509 -req -in server.csr -days 3650 -sha384 -CA rootCA.pem -CAkey rootCA.key \
        -CAcreateserial -out server.pem -extensions v3_req -extfile openssl.conf

    echo "Create a .p12 file that contains both server cert and private key"
    openssl pkcs12 -export -in server.pem -inkey server.key \
        -out server.p12 -name cert -password pass:changeit

    echo "Import signed certificate into the keystore"
    keytool -importkeystore \
        -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass changeit \
        -deststorepass "${KEYSTORE_PASSWORD}" -destkeypass "${KEYSTORE_PASSWORD}" \
        -destkeystore "${KEY_STORE}" -alias cert

    rm server.p12 server.csr
}

generate_root_ca() {
    echo "Generating root CA for the server certificates into rootCA.pem and rootCA.key"
    openssl req \
      -x509 \
      -newkey rsa:2048 \
      -days 3650 \
      -sha256 \
      -nodes \
      -subj "/CN=config_server_ca" \
      -keyout rootCA.key \
      -out rootCA.pem
}

setup_auth_server_trust_store() {
    echo "Adding dev UAA CA to auth server trust store"
    keytool -import \
        -trustcacerts \
        -noprompt \
        -alias auth_server_ca \
        -file ${UAA_CA} \
        -keystore ${AUTH_SERVER_TRUST_STORE} \
        -storepass ${KEYSTORE_PASSWORD}
}

main() {
    pushd "${DIRNAME}" >/dev/null
        clean
        generate_root_ca
        setup_tls_key_store
        setup_auth_server_trust_store

        echo "Finished setting up key stores for TLS!"
    popd >/dev/null
}

main
