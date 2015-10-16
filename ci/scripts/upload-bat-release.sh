#!/bin/bash

bosh -t $director_target -u $director_user -p $director_password upload release bat-release-artifact/*.tgz 

echo $?
