#!/usr/bin/env bash

set -e -x

trap clean_vagrant EXIT

./() {
  key_path=$(mktemp -d /tmp/ssh_key.XXXXXXXXXX)/value
  echo "$BOSH_PRIVATE_KEY" > $key_path
  chmod 600 $key_path
  export BOSH_VAGRANT_KEY_PATH=$key_path
  eval `ssh-agent`
  ssh-add $key_path
}

clean_vagrant() {
   true
}

get_ip_from_vagrant_ssh_config() {
  config=$(vagrant ssh-config remote)
  echo $(echo "$config" | grep HostName | awk '{print $2}')
}

build_num=$(cat stemcell-version/number | cut -f1 -d.)

pushd bosh-src

# todo check out correct version of bosh-src for that stemcell
# git checkout stable-${build_num}
# git submodule update --init --recursive
# git clean -fdx

bundle

cd bosh-stemcell

set_up_vagrant_private_key

vagrant up remote --provider=aws

vagrant ssh -c "
  cd /bosh
  bundle
  export CANDIDATE_BUILD_NUMBER=$build_num
  bundle exec rake stemcell:build[$IAAS,$HYPERVISOR,$OS_NAME,$OS_VERSION,go,bosh-os-images,bosh-$OS_NAME-$OS_VERSION-os-image.tgz]
" remote

builder_ip=$(get_ip_from_vagrant_ssh_config)

popd

scp ubuntu@${builder_ip}:/bosh/tmp/*.tgz build/