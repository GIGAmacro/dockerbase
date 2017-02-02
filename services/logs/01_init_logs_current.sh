#!/bin/bash
set -e

if [ -e /VERSION ]; then
    VERSION=$(cat /VERSION)
else
    VERSION=noversion
fi

# logs CURRENT
if [[ -v DEV_MODE ]]; then
    rm -rf /shared/logs/CURRENT
    mkdir -p /shared/logs/CURRENT
else
    mkdir -p "/shared/logs/$VERSION"
    cd /shared/logs
    rm -f CURRENT
    ln -s "$VERSION" CURRENT
fi

