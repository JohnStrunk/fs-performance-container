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
        # Must set the Git identity or the git clone generates an error
        export GIT_COMMITTER_NAME="nobody"
        export GIT_COMMITTER_EMAIL="nobody@nowhere.com"

        measure_time "Time to clone Git repository" "git clone -q '${CLONE_REPO}' '${TARGET_PATH}/repo' && sync"
        measure_time "Time to remove cloned files" "rm -rf '${TARGET_PATH}/repo' && sync"
}

function bench_fio {
        local FILE="${TARGET_PATH}/testfile"
        local result
        local FIO_ARGS=(
                "--filesize=${FIO_CAPACITY_MB}M"
                "--runtime=${FIO_RUNTIME}s"
                "--filename=$FILE"
                "--ioengine=libaio"
                "--direct=1"
                "--time_based"
                "--stonewall"
                "--eta=never"
                "--output-format=json"
        )

        # Test max I/O bandwidth via 1 MB sequential writes w/ qd=32
        result="$(fio "${FIO_ARGS[@]}" --name=sw1m@qd32 --iodepth=32 --bs=1m --rw=write | \
                jq '.jobs[0].write.bw / 1024 | round')"
        echo -e "\tMax write bandwidth: ${result} MiB/s"

        # Test max I/O bandwidth via 1 MB sequential reads w/ qd=32
        result="$(fio "${FIO_ARGS[@]}" --name=sr1m@qd32 --iodepth=32 --bs=1m --rw=read | \
                jq '.jobs[0].read.bw / 1024 | round')"
        echo -e "\tMax read bandwidth: ${result} MiB/s"

        # Test I/O latency via 4k random writes w/ qd=1
        result="$(fio "${FIO_ARGS[@]}" --name=rw4k@qd1 --iodepth=1 --bs=4k --rw=randwrite | \
                jq '.jobs[0].write.clat_ns.mean / 1000 | round / 1000')"
        echo -e "\tWrite I/O latency: ${result} ms"

        # Test I/O latency via 4k random reads w/ qd=1
        result="$(fio "${FIO_ARGS[@]}" --name=rr4k@qd1 --iodepth=1 --bs=4k --rw=randread | \
                jq '.jobs[0].read.clat_ns.mean / 1000 | round / 1000')"
        echo -e "\tRead I/O latency: ${result} ms"

        # Test max I/O throughput via 4k random writes w/ qd=32
        result="$(fio "${FIO_ARGS[@]}" --name=rw4k@qd32 --iodepth=32 --bs=4k --rw=randwrite | \
                jq '.jobs[0].write.iops | round')"
        echo -e "\tMax write throughput: ${result} IOPS"

        # Test max I/O throughput via 4k random reads w/ qd=32
        result="$(fio "${FIO_ARGS[@]}" --name=rr4k@qd32 --iodepth=32 --bs=4k --rw=randread | \
                jq '.jobs[0].read.iops | round')"
        echo -e "\tMax read throughput: ${result} IOPS"

        rm -f "$FILE"
}

function bench_kernel {
        mkdir -p "${TARGET_PATH}/kernel"
        measure_time "Time to untar linux kernel" "tar -C '${TARGET_PATH}/kernel' -xJf /kernel.tar.xz && sync"
        measure_time "Time to delete untar-ed files" "rm -rf '${TARGET_PATH}/kernel' && sync"
}

function bench_null {
        echo NULL benchmark
}

#-- Environment variables used to configure the container
# configurable "VARNAME" "DEFAULT_VALUE_IF_NOT_SET" "Text description"
function configurable {
        local VARNAME="$1"
        local DEFAULT="$2"
        local DESCRIPTION="$3"

        [[ -n ${!VARNAME} ]] || export "$VARNAME"="$DEFAULT"

        echo -e "\t$DESCRIPTION: ${!VARNAME}  ($VARNAME)"
}

#-- Run a command and print out how long it took
# measure_time "Text description" "command_that_will_be_run_via bash -c"
function measure_time {
        local DESCRIPTION="$1"
        local CMD="$2"

        local TIMEFILE; TIMEFILE="$(mktemp)"

        /usr/bin/time -f "%e s" -o "$TIMEFILE" bash -c "$CMD"
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
configurable BENCHMARKS "clone fio kernel" "List of benchmarks to run"
configurable TARGET_PATH "/target" "Target path for tests"
configurable ITERATIONS 1 "Number of test iterations to run"
configurable STARTUP_DELAY 0 "Random startup delay (s)"
configurable RAND_THINK 0 "Random delay between iterations (s)"
configurable DELETE_FIRST 0 "Delete contents of target dir on startup"
configurable FIO_CAPACITY_MB 500 "File size for fio benchmark"
configurable FIO_RUNTIME 120 "Runtime for individual fio tests (s)"
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
