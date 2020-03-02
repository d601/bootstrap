#!/usr/bin/env bash

set -euxo pipefail

if [ "$(hostname)" == "localhost.localdomain" ]; then
    echo "hostname is unset, please set it now"
    read -p "New hostname: " new_hostname
    sudo hostnamectl set-hostname "${new_hostname}"
fi

declare packages="lsb-release python3-devel jq keepassxc git"

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

read -p "Path to keyfile: " keyfile
sudo cp "${keyfile}" ~/Documents/Cloud2.key
sudo chown $(whoami):users ~/Documents/Cloud2.key

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
gsutil cp "${secrets_bucket}Backups/Cloud2.kdbx" ~/Documents/

# Generate ssh key
if [ ! -e ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -f ~/.ssh/id_rsa
fi

echo -n "Enter the password for keepass: "
declare -r github_api_key=$(keepassxc-cli show -s -a Password -k ~/Documents/Cloud2.key ~/Documents/Cloud2.kdbx 'github token' | sed 's/Enter.*: //g')
declare -r github_key_name="$(whoami)@$(hostname)"
github_curl() {
    curl -H "Authorization: token ${github_api_key}" $@
}

# Check if we already have a key with this name. If we do, overwrite it.
declare -r existing_github_key_id=$(github_curl -s https://api.github.com/user/keys) | jq --raw-output ".[] | select(.title==\"${github_key_name}\") | .id"
if [ -n "${existing_github_key_id}" ]; then
    github_curl -XDELETE "https://api.github.com/user/keys/${existing_github_key_id}"
fi

github_curl -XPOST -d "{\"title\": \"${github_key_name}\", \"key\": \"$(cat ~/.ssh/id_rsa)\"}" https://api.github.com/user/keys

mkdir ~/repos/
(cd ~/repos/ && git clone git@github.com:d601/saltconfigs.git)

# git config --global user.name d601
# Set email separately so that info isn't exposed here

# Install salt
# declare -r salt_version=2019.2.3
# declare -r salt_hash=efc46700aca78b8e51d7af9b06293f52ad495f3a8179c6bfb21a8c97ee41f1b7
# declare -r salt_filename=bootstrap-salt.sh

# curl -o "${salt_filename}" -L https://bootstrap.saltstack.com
# echo "${salt_hash} ${salt_filename}" | sha256sum --check
# sudo bash ./"${salt_filename}" -X -x python3 git "${salt_version}"
