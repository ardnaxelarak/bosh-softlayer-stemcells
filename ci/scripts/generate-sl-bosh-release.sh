#!/bin/bash

set -e

sed --in-place '/ignore_missing_gateway/s/^/#/' bosh/release/jobs/director/templates/director.yml.erb.erb

cat -n bosh/release/jobs/director/templates/director.yml.erb.erb

pushd bosh
    bundle install
popd

pushd bosh/bosh-dev
    bundle exec rake release:create_dev_release
popd

pushd bosh/release
    bosh create release --force --with-tarball
popd

mkdir out

cp bosh/release/dev_releases/bosh/*.tgz out/

for file in out/*.tgz; do
    mv $file ${file//bosh/sl-bosh}
done
