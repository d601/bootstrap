#!/usr/bin/env bash

set -euxo pipefail

declare -r salt_version=3003

curl -o bootstrap-salt.sh -L https://bootstrap.saltstack.com
sha256sum bootstrap-salt.sh
