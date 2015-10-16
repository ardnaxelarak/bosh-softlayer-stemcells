#!/bin/bash

set -e

bosh upload release bat-release-artifact/*.tgz -t $director_target -u $director_user -p $director_password
