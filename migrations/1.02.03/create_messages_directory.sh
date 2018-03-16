#!/bin/bash

DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p ${DIR_DATA}/messages/queues/actionability/ac-release-wag/
mkdir -p ${DIR_DATA}/messages/conf
cp ${DIR_SCRIPT}/ac-release-wag.json ${DIR_DATA}/messages/conf/
