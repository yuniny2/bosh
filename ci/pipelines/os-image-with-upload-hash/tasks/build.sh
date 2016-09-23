#!/bin/bash

set -eu

TASK_DIR=$PWD

cd bosh-src

source ci/tasks/utils.sh
check_param OPERATING_SYSTEM_NAME
check_param OPERATING_SYSTEM_VERSION

OS_IMAGE_NAME=$OPERATING_SYSTEM_NAME-$OPERATING_SYSTEM_VERSION
OS_IMAGE=$TASK_DIR/os-image/$OS_IMAGE_NAME-$( cat $TASK_DIR/version/number ).tgz

sudo chown -R ubuntu .
sudo --preserve-env --set-home --user ubuntu -- /bin/bash --login -i <<SUDO
    bundle install --local
    bundle exec rake stemcell:build_os_image[$OPERATING_SYSTEM_NAME,$OPERATING_SYSTEM_VERSION,$OS_IMAGE] >> output.txt

    cat output.txt
    
    while read outputLine; do
    	if [[ $outputLine =~ "OS image file version uploaded to S3 is" ]]
    	then
    		version=${outputLine/*:/\"\"}
    		echo "version is: ${version}"
    	fi
    done < output.txt

    git log -n 1 >> sha.txt
    line=$(head -n 1 sha.txt)
	arr=($line)
	sha=${arr[1]}

	# grabbing message on commit
	message=`git log --pretty=oneline --abbrev-commit -n 1`
	echo -e "* \`$version\`\n" >> bosh-stemcell/OS_IMAGES.md
	echo -e "  - $message\n" >> bosh-stemcell/OS_IMAGES.md

	# replacing the right uploaded blob hash in the json file
	FILE=os_image_versions.json

	while read line; do
		if [[ $line =~ $OPERATING_SYSTEM_NAME && $line =~ $OPERATING_SYSTEM_VERSION ]]
		then
			LAST_CHAR=""

			# because we want to know whether or not we need a comma
			if [[ ${line: -1} == "," ]]
			then
				LAST_CHAR=','
			fi

			line=${line/:*/:\"$version\"$LAST_CHAR}
			echo $line
		fi

		echo $line >> tmprandomname.json
	done < $FILE

	cp tmprandomname.json $FILE
	rm -rf tmprandomname.json

	# committing
	git config --global user.email salvi@pivotal.io 
	git config --global user.name SamanGit

	git add README.md
	git add test.json
	git commit -m "updating message"

	cd ..

	# it's annoying that there's no work around for manually copying over all the files
	cp -a bosh-src/ bosh-out/
SUDO
