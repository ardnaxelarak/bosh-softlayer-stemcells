#!/usr/bin/env bash

set -e -x

[ -f vsphere-stemcell/version ] || exit 1

echo "$(cat vsphere-stemcell/version).0.0" > semver
