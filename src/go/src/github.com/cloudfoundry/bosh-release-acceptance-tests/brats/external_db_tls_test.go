package brats_test

import (
	"fmt"
	"strings"

	"io/ioutil"
	"log"
	"os"
	"path/filepath"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/ginkgo/extensions/table"
)

var _ = Describe("Director external database TLS connections", func() {
	AfterEach(func() {
		stopInnerBosh()
	})

	testDBConnectionOverTLS := func(databaseType string, mutualTLSEnabled bool, useInvalidCA bool, useIncorrectClientCertAndKey bool) {
		external_db_host := assertEnvExists(fmt.Sprintf("%s_EXTERNAL_DB_HOST", strings.ToUpper(databaseType)))
		external_db_user := assertEnvExists(fmt.Sprintf("%s_EXTERNAL_DB_USER", strings.ToUpper(databaseType)))
		external_db_password := assertEnvExists(fmt.Sprintf("%s_EXTERNAL_DB_PASSWORD", strings.ToUpper(databaseType)))
		external_db_name := assertEnvExists(fmt.Sprintf("%s_EXTERNAL_DB_NAME", strings.ToUpper(databaseType)))

		connectionOptions := fmt.Sprintf("external_db/%s_connection_options.yml", databaseType)

		connectionVarFile := fmt.Sprintf("external_db/%s.yml", databaseType)
		if useInvalidCA {
			connectionVarFile = fmt.Sprintf("external_db/%s_invalid_ca.yml", databaseType)
		}

		startInnerBoshArgs := []string{
			fmt.Sprintf("-o %s", boshDeploymentAssetPath("misc/external-db.yml")),
			fmt.Sprintf("-o %s", boshDeploymentAssetPath("experimental/db-enable-tls.yml")),
			fmt.Sprintf("-o %s", assetPath(connectionOptions)),
			fmt.Sprintf("--vars-file %s", assetPath(connectionVarFile)),
			fmt.Sprintf("-v external_db_host=%s", external_db_host),
			fmt.Sprintf("-v external_db_user=%s", external_db_user),
			fmt.Sprintf("-v external_db_password=%s", external_db_password),
			fmt.Sprintf("-v external_db_name=%s", external_db_name),
		}

		if mutualTLSEnabled {
			external_db_client_certificate := assertEnvExists(fmt.Sprintf("%s_EXTERNAL_DB_CLIENT_CERTIFICATE", strings.ToUpper(databaseType)))
			external_db_client_private_key := assertEnvExists(fmt.Sprintf("%s_EXTERNAL_DB_CLIENT_PRIVATE_KEY", strings.ToUpper(databaseType)))

			tempDir, err := ioutil.TempDir("", "bosh_db_tls")
			if err != nil {
				log.Fatal(err)
			}

			defer os.RemoveAll(tempDir)

			external_db_client_certificate_file := filepath.Join(tempDir, "external_db_client_certificate")
			if err := ioutil.WriteFile(external_db_client_certificate_file, []byte(external_db_client_certificate), 0666); err != nil {
				log.Fatal(err)
			}

			external_db_client_private_key_file := filepath.Join(tempDir, "external_db_client_private_key")
			if err := ioutil.WriteFile(external_db_client_private_key_file, []byte(external_db_client_private_key), 0666); err != nil {
				log.Fatal(err)
			}

			mutualTLSArgs := []string{
				fmt.Sprintf("-o %s", boshDeploymentAssetPath("experimental/db-enable-mutual-tls.yml")),
				fmt.Sprintf("--var-file=db_client_certificate=%s", external_db_client_certificate_file),
				fmt.Sprintf("--var-file=db_client_private_key=%s", external_db_client_private_key_file),
			}

			startInnerBoshArgs = append(startInnerBoshArgs, mutualTLSArgs...)
		}

		startInnerBoshWithExpectation(!useInvalidCA, startInnerBoshArgs...)

		uploadRelease("https://bosh.io/d/github.com/cloudfoundry/syslog-release?v=11")
	}

	Context("RDS", func() {
		// RDS Mutual TLS not supported
		var mutualTLSEnabled = false
		var useInvalidCA = false
		var useIncorrectClientCertAndKey = false

			DescribeTable("Regular TLS", testDBConnectionOverTLS,
			Entry("allows TLS connections to MYSQL", "rds_mysql", mutualTLSEnabled, useInvalidCA, useIncorrectClientCertAndKey),
			Entry("allows TLS connections to POSTGRES", "rds_postgres", mutualTLSEnabled, useInvalidCA, useIncorrectClientCertAndKey),
		)
	})

	Context("GCP", func() {

		Context("Regular TLS", func() {
			var mutualTLSEnabled = false
			var useInvalidCA = false
			var useIncorrectClientCertAndKey = false

			DescribeTable("DB Connections", testDBConnectionOverTLS,
				Entry("allows TLS connections to MYSQL", "gcp_mysql", mutualTLSEnabled, useInvalidCA, useIncorrectClientCertAndKey),
				Entry("allows TLS connections to POSTGRES", "gcp_postgres", mutualTLSEnabled, useInvalidCA, useIncorrectClientCertAndKey),
			)

			Context("Incorrect CA", func() {
				useInvalidCA = true

				DescribeTable("DB Connections", testDBConnectionOverTLS,
					FEntry("fails to connect to MYSQL", "gcp_mysql", mutualTLSEnabled, useInvalidCA, useIncorrectClientCertAndKey),
					Entry("fails to connect to POSTGRES", "gcp_postgres", mutualTLSEnabled, useInvalidCA, useIncorrectClientCertAndKey),
				)
			})
		})

		Context("Mutual TLS", func() {
			var mutualTLSEnabled = true
			var useInvalidCA = false
			var useIncorrectClientCertAndKey = false

			DescribeTable("DB Connections", testDBConnectionOverTLS,
				Entry("allows TLS connections to MYSQL", "gcp_mysql", mutualTLSEnabled, useInvalidCA, useIncorrectClientCertAndKey),
				Entry("allows TLS connections to POSTGRES", "gcp_postgres", mutualTLSEnabled, useInvalidCA, useIncorrectClientCertAndKey),
			)

			Context("Incorrect client cert and key", func() {
				useIncorrectClientCertAndKey = true

				DescribeTable("DB Connections", testDBConnectionOverTLS,
					Entry("fails to connect to MYSQL", "gcp_mysql", mutualTLSEnabled, useInvalidCA, useIncorrectClientCertAndKey),
					Entry("fails to connect to POSTGRES", "gcp_postgres", mutualTLSEnabled, useInvalidCA, useIncorrectClientCertAndKey),
				)
			})
		})
	})


	//DescribeTable("GCP", testDBConnectionOverTLS,
	//	Entry("allows TLS connections to MYSQL", "gcp_mysql", false, false),
	//	Entry("does not allow TLS connections to MYSQL using invalid server CA", "gcp_mysql", false, true),
	//	Entry("allows TLS connections to POSTGRES", "gcp_postgres", false, false),
	//	Entry("does not allow TLS connections to POSTGRES using invalid server CA", "gcp_postgres", false, true),
	//
	//	Entry("allows Mutual TLS connections to MYSQL", "gcp_mysql", true, false),
	//	Entry("allows Mutual TLS connections to POSTGRES", "gcp_postgres", true, false),
	//)
})
