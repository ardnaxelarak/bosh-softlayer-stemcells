#!/bin/bash

set -e

gem uninstall -a bosh_cli

gem install bosh_cli -v '=1.2650.0'

base=$( cd "$( dirname "$( dirname "$( dirname "$0" )")")" && pwd )
base_gopath=$( cd $base/../../../.. && pwd )

version=`cat version/number`

mkdir $base_gopath/out

export GOPATH=$base/Godeps/_workspace:$base_gopath:$GOPATH

cd $base/../bosh-softlayer-cpi-release

# gem install bosh_cli --no-ri --no-rdoc

echo "using bosh CLI version..."
bosh version

cpi_release_name="bosh-softlayer-cpi-release"

rm -R src/golang_1.3

echo "building CPI release..."
bosh create release --name $cpi_release_name --version $version --with-tarball --force

mv dev_releases/$cpi_release_name/$cpi_release_name*.tgz $base_gopath/out
