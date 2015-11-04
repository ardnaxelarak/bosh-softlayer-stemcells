#!/bin/bash

(
  set -e

  echo -e "\n Get stemcell version..."
  STEMCELL_VERSION=`cat vsphere-stemcell/version`
  echo $STEMCELL_VERSION > stemcell-version
)
