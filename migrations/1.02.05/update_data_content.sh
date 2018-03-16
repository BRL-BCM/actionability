#!/bin/bash

DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p ${DIR_DATA}/messages/archive/actionability/ac-release-wag/
cp ${DIR_SCRIPT}/ac-release-wag.client-ssl.no-jks.properties ${DIR_DATA}/messages/conf/
chmod 600 ${DIR_DATA}/messages/conf/ac-release-wag.client-ssl.no-jks.properties
