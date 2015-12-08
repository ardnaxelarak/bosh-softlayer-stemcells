#!/bin/bash

(
  set -e

  echo -e "\n Creating archive with bosh_cli..."
  version=`cat version/number`
  filename="bosh-softlayer-cpi-release"
  extension=".tgz"
  cp bosh-softlayer-private/private.yml bosh-softlayer-cpi-release/config/.
  cd bosh-softlayer-cpi-release
  yes | bosh create release --final --with-tarball --name "$filename" --version "$version" --force

  cp releases/bosh-softlayer-cpi-release/"$filename-$version.tgz" ../.
)
