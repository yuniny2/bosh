#!/usr/bin/env bash

set -eu

fly -t production set-pipeline -p configure-rds-pipe \
    -c ci/configure-rds-pipe.yml \
    --load-vars-from <(lpass show -G "bosh concourse secrets" --notes)
