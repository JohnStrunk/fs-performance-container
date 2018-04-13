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


# This script runs the fs-performance tests using the local docker daemon

docker run -d \
    --name fs-performance \
    -e TARGET_CAPACITY_MB="500" \
    -e TARGET_PATH="/target" \
    -e CLONE_REPO="https://github.com/gluster/glusterfs.git" \
    -e ITERATIONS="1" \
    -e RAND_SLEEP="0" \
    -e RAND_THINK="0" \
    -e DO_DELETE="0" \
    quay.io/johnstrunk/fs-performance:latest
    #-v /system_under_test:/target \
