#!/bin/bash
set -e

if [ -e /VERSION ]; then
    VERSION=$(cat /VERSION)
else
    VERSION=noversion
fi

# logs CURRENT
mkdir -p "/shared/logs/$VERSION"
cd /shared/logs
rm -f CURRENT
ln -s "$VERSION" CURRENT

