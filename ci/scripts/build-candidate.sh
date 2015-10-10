#!/usr/bin/env bash

set -e

mkdir out

semver=`cat version`

cd bosh-cpi-release

echo "running unit tests"
pushd src/bosh_aws_cpi
  bundle install
  bundle exec rspec spec/unit/*
popd

echo "using bosh CLI version..."
bosh version

cpi_release_name="bosh-sl-cpi"

echo "building CPI release..."
bosh create release --name $cpi_release_name --version $semver --with-tarball

mv dev_releases/$cpi_release_name/$cpi_release_name-$semver.tgz ../out/
