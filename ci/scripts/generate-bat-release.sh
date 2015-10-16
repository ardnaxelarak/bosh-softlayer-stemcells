#!/bin/bash

set -e

pushd bats/spec/system/assets/bat-release
  bosh create release --force --name bat --version 2 --with-tarball --target $director_target --user $director_user --password $director_password
popd

mkdir out

cp bats/spec/system/assets/bat-release/dev-releases/bat/*.tgz out/
