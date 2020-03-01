#!/usr/bin/env bash

set -euxo pipefail

# We assume tumbleweed
sudo zypper in lsb-release python3-dev

declare -r salt_version=3000
declare -r salt_hash=efc46700aca78b8e51d7af9b06293f52ad495f3a8179c6bfb21a8c97ee41f1b7
declare -r salt_filename=bootstrap-salt.sh

curl -o "${salt_filename}" -L https://bootstrap.saltstack.com
echo "${salt_hash} ${salt_filename}" | sha256sum --check
chmod +x "${salt_filename}"
sudo exec ./"${salt_filename}" -X -x python3 git "${salt_version}"
