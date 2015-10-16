#!/bin/bash

set -e

pushd bats/spec/system/assets/bat-release
  bosh create release --force --name bat --version 2 --with-tarball
popd

mkdir out

cp bats/spec/system/assets/bat-release/dev_releases/bat/*.tgz out/
