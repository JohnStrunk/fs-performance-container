#! /bin/bash
# vim: set ts=4 sw=4 et :

# Copyright 2018 Red Hat, Inc. and/or its affiliates.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -ex

#-- Run benchmarks from command line or this set as default
BENCH_TO_RUN=(${@-clone fio kernel maven})

#-- Use approximately this much storage for the tests
TARGET_CAPACITY_MB=${TARGET_CAPACITY_MB:-500}

#-- Where to find the system under test
TARGET_PATH="${TARGET_PATH:-/target}"

#-- Repo used for the clone test
CLONE_REPO="${CLONE_REPO:-https://github.com/gluster/glusterfs.git}"

#-- Number of iterations to run
ITERATIONS=${ITERATIONS:-1}



function time_wrap {
    echo "=== Starting $* at $(date) ==="
    "$@"
    echo "=== Finished $* at $(date) ==="
}

function bench_clone {
    #-- git clone
    time (git clone "${CLONE_REPO}" "${TARGET_PATH}/repo" && sync)

    #-- remove cloned repo
    time (rm -rf "${TARGET_PATH}/repo" && sync)
}

function bench_fio {
    local FILE
    FILE="${TARGET_PATH}/testfile"
    fio --filesize="${TARGET_CAPACITY_MB}M" --runtime=120s --ioengine=libaio --direct=1 --time_based --stonewall --filename="$FILE" --eta=never \
        --name=sw1m@qd32 --description="Bandwidth via 1MB sequential writes @ qd=32" --iodepth=32 --bs=1m --rw=write \
        --name=sr1m@qd32 --description="Bandwidth via 1MB sequential reads @ qd=32" --iodepth=32 --bs=1m --rw=read \
        --name=rw4k@qd1 --description="e2e latency via 4k random writes @ qd=1" --iodepth=1 --bs=4k --rw=randwrite \
        --name=rr4k@qd1 --description="e2e latency via 4k random reads @ qd=1" --iodepth=1 --bs=4k --rw=randread \
        --name=rw4k@qd32 --description="IOPS via 4k random writes @ qd=32" --iodepth=32 --bs=4k --rw=randwrite \
        --name=rr4k@qd32 --description="IOPS via 4k random reads @ qd=32" --iodepth=32 --bs=4k --rw=randread
    rm -f "$FILE"
}

function bench_kernel {
    mkdir -p "${TARGET_PATH}/kernel"
    cd "${TARGET_PATH}/kernel"
    time (tar xJf /kernel.tar.xz && sync)
    cd
    time (rm -rf "${TARGET_PATH}/kernel" && sync)
}

function bench_maven {
    # make sure the maven local repository goes into the target directory, too
    mkdir -p "${TARGET_PATH}/h/.m2"
    rm -rf "${HOME}/.m2"
    #-- this may fail if no home dir exists
    ln -s "${TARGET_PATH}/h/.m2" "${HOME}/.m2" || true
    #-- direct mvn where we want in case home dir isn't set
    export HOME="${TARGET_PATH}/h"

    #-- Maven build
    echo "FIRST BUILD (empty cache)"
    time git clone https://github.com/jfctest1/benchapp2.git "${TARGET_PATH}/repo"
    cd "${TARGET_PATH}/repo"
    time mvn clean -B -e -U compile -Dmaven.test.skip=false -P openshift

    echo "SECOND BUILD (cached artifacts)"
    cd "${TARGET_PATH}/repo"
    time mvn clean -B -e -U compile -Dmaven.test.skip=false -P openshift

    cd
    time rm -rf "${TARGET_PATH}/repo"
}



# /target is the place that we do our I/O. Make sure it's writable
if ! touch "${TARGET_PATH}/dest_is_writable"; then
    echo "Error: Target directory ${TARGET_PATH} is not writable. Exiting"
    exit 1
fi

echo "Target capacity (MB): ${TARGET_CAPACITY_MB}"
echo "Target path: ${TARGET_PATH}"

while [ "$ITERATIONS" -gt 0 ]; do
    for bench in "${BENCH_TO_RUN[@]}"; do
        case $bench in
        clone)
            time_wrap bench_clone
            ;;
        fio)
            time_wrap bench_fio
            ;;
        kernel)
            time_wrap bench_kernel
            ;;
        maven)
            time_wrap bench_maven
            ;;
        *)
            echo "Unknown benchmark: $bench"
            exit 1
            ;;
        esac
    done
    ITERATIONS=$(( ITERATIONS - 1 ))
done
