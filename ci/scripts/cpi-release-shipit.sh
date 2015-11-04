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

  # bosh upload release
  echo -e "\n Created archive...\n Uploaded to S3 Bucket"
  # cd releases
  # cd bosh-softlayer-cpi-release
  # ls | sed 's/.*foo//'
  cp releases/bosh-softlayer-cpi-release/"$filename-$version.tgz" ../.
  # s3cmd put releases/bosh-softlayer-cpi-release/"$filename-$version.tgz" s3://bosh-softlayer-cpi-stemcells --access_key=$S3_ACCESS_KEY --secret_key=$S3_SECRET_KEY
  # cp dev_releases/bosh-softlayer-cpi-release/"$filename-$version.yml" ../.
  # tar -cvzf "$filename$version$extension" bosh-softlayer-cpi-release/*
)
