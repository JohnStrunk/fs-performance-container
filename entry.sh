#! /bin/bash

# /target is the place that we do our I/O. Make sure it's writable
touch /target/dest_is_writable
if [[ $? -ne 0 ]]; then
    echo Error: Target directory /target is not writable. Exiting
    exit 1
fi

/usr/bin/fio fio/default.fio
