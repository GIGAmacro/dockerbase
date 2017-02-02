#!/usr/bin/env bash

docker run --name gigabase --rm -it \
    -v gigamacro_data:/data \
    -v "$(pwd)/../../../shared":/shared \
    gigamacrodocker/viewerbase:latest \
    /sbin/my_init -- bash -l

