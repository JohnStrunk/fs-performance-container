#! /bin/bash

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

if [[ ${DEBUG:=0} -gt 0 ]]; then
        set -x
fi

function bench_clone {
        measure_time "Time to clone Git repository" "git clone -q '${CLONE_REPO}' '${TARGET_PATH}/repo' && sync"
        measure_time "Time to remove cloned files" "rm -rf '${TARGET_PATH}/repo' && sync"
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
        measure_time "Time to untar linux kernel" "tar -C '${TARGET_PATH}/kernel' -xJf /kernel.tar.xz && sync"
        measure_time "Time to delete untar-ed files" "rm -rf '${TARGET_PATH}/kernel' && sync"
}

#-- Environment variables used to configure the container
# configurable "VARNAME" "DEFAULT_VALUE_IF_NOT_SET" "Text description"
function configurable {
        local VARNAME="$1"
        local DEFAULT="$2"
        local DESCRIPTION="$3"

        echo -e "\t$DESCRIPTION: ${!VARNAME:=$DEFAULT}  ($VARNAME)"
}

#-- Run a command and print out how long it took
# measure_time "Text description" "command_that_will_be_run_via bash -c"
function measure_time {
        local DESCRIPTION="$1"
        local CMD="$2"

        local TIMEFILE; TIMEFILE="$(mktemp)"

        /usr/bin/time -f %es -o "$TIMEFILE" bash -c "$CMD"
        echo -e "\t${DESCRIPTION}: $(cat "$TIMEFILE")"

        rm -f "$TIMEFILE"
}

function random_sleep {
        if [ "$1" -gt 0 ]; then
                local AMT=$(( RANDOM % $1))
                echo "Sleeping for ${AMT}s"
                sleep "${AMT}"
        fi
}




echo Configuration:
configurable BENCHMARKS "clone kernel" "List of benchmarks to run"
configurable TARGET_PATH "/target" "Target path for tests"
configurable ITERATIONS 1 "Number of test iterations to run"
configurable STARTUP_DELAY 0 "Random startup delay (s)"
configurable RAND_THINK 0 "Random delay between iterations (s)"
configurable DELETE_FIRST 0 "Delete contents of target dir on startup"
configurable FIO_CAPACITY_MB 500 "File size for fio benchmark"
configurable CLONE_REPO "https://github.com/gluster/glusterfs.git" "Git repo to use for clone test"

# /target is the place that we do our I/O. Make sure it's writable
if ! touch "${TARGET_PATH}/dest_is_writable"; then
        echo "Error: Target directory ${TARGET_PATH} is not writable. Exiting"
        exit 1
fi

random_sleep "$STARTUP_DELAY"

if [[ "${DELETE_FIRST}" -gt 0 ]]; then
        echo "Cleaning target dir"
        rm -rf "${TARGET_PATH:?}/*"
fi

while [ "$ITERATIONS" -gt 0 ]; do
        for bench in ${BENCHMARKS}; do
                echo "Benchmark: $bench"
                "bench_$bench" || exit 1
        done
        random_sleep "$RAND_THINK"
        ITERATIONS=$(( ITERATIONS - 1 ))
done
