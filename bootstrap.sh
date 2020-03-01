#!/usr/bin/env bash

set -euxo pipefail

declare -r salt_version=3003
declare -r salt_hash=efc46700aca78b8e51d7af9b06293f52ad495f3a8179c6bfb21a8c97ee41f1b7
declare -r salt_filename=bootstrap-salt.sh

curl -o "${salt_filename}" -L https://bootstrap.saltstack.com
echo "${salt_hash} ${salt_filename}" | sha256sum --check
# if [ $? -ne 0 ]; then
