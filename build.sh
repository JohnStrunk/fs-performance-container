#! /bin/bash

BUILDDATE=$(date -u '+%Y-%m-%dT%H:%M:%S.%NZ')
VERSION=$(git describe --match 'v[0-9]*' --tags --dirty 2> /dev/null || git describe --always --dirty)

docker build \
        -t "${CONTAINER_REPO:=quay.io/johnstrunk/fs-performance}" \
        --build-arg "builddate=$BUILDDATE" \
        --build-arg "version=$VERSION" \
        .
