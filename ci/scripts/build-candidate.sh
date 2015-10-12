#!/bin/bash

set -e

base=$( cd "$( dirname "$( dirname "$( dirname "$0" )")")" && pwd )
base_gopath=$( cd $base/../../../.. && pwd )

mkdir $base_gopath/out

export GOPATH=$base/Godeps/_workspace:$base_gopath:$GOPATH

cd $base/../bosh-softlayer-cpi-release

gem install bosh_cli

echo "using bosh CLI version..."
bosh version

cpi_release_name="bosh-sl-cpi"

echo "building CPI release..."
bosh create release --name $cpi_release_name --with-tarball

mv dev_releases/$cpi_release_name/$cpi_release_name.tgz $base_gopath/out
