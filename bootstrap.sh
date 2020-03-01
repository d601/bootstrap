#!/usr/bin/env bash

set -euxo pipefail

declare packages="lsb-release python3-devel jq keepassxc"

if hostnamectl | grep -q Virtualization; then
    declare packages="${packages} kernel-devel"
    declare is_virtualbox=y
fi

# We assume tumbleweed
sudo zypper in -y ${packages}

# You need to mount the guest additions disk before running this
if [ -n "${is_virtualbox:-}" ]; then
    # No idea how to automatically figure this out
    udisksctl mount -b /dev/sr0
    /run/media/$(whoami)/VBox_GAs_*/autorun.sh
fi

prompt -p "Path to keyfile: " keyfile
sudo cp "${keyfile}" ~/Documents/Cloud2.key
sudo chown $(whoami):$(whoami) ~/Documents/Cloud2.key

# Install gcloud
# I don't think they publish hashes for this
if [ ! -e ~/google-cloud-sdk ]; then
    curl https://sdk.cloud.google.com > gcloud_installer
    chmod +x gcloud_installer
    bash ./gcloud_installer --disable-prompts
fi
./google-cloud-sdk/install.sh -q --command-completion true --path-update true
source ~/.bashrc
# This will pop up a browser window. Time to login
gcloud auth login

# I'm paranoid, so set this stuff not by name
gcloud config set project $(gcloud projects list --format json | jq --raw-output '.[0] | .projectId')
declare -r secrets_bucket=$(gsutil ls | tail -n1)
gsutil cp "${secrets_bucket}/Backups/Cloud2.kdbx" ~/Documents/

# Install salt
# declare -r salt_version=2019.2.3
# declare -r salt_hash=efc46700aca78b8e51d7af9b06293f52ad495f3a8179c6bfb21a8c97ee41f1b7
# declare -r salt_filename=bootstrap-salt.sh

# curl -o "${salt_filename}" -L https://bootstrap.saltstack.com
# echo "${salt_hash} ${salt_filename}" | sha256sum --check
# sudo bash ./"${salt_filename}" -X -x python3 git "${salt_version}"
