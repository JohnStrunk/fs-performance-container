# fs-performance-container

[![Build
Status](https://travis-ci.com/JohnStrunk/fs-performance-container.svg?branch=master)](https://travis-ci.com/JohnStrunk/fs-performance-container)
[![Docker Repository on
Quay](https://quay.io/repository/johnstrunk/fs-performance/status "Docker
Repository on Quay")](https://quay.io/repository/johnstrunk/fs-performance)

A container that measures file system performance

## Usage

This container can be run "manually" in a container on the local machine or in a
Kubernetes cluster as a Job.

### Running locally

To run the benchmarks locally, use `docker` or `podman` to start the container,
and attach the file system to test at `/target` within the container:

```
$ docker run -v /mytestdir:/target quay.io/johnstrunk/fs-performance
Configuration:
        List of benchmarks to run: clone fio kernel  (BENCHMARKS)
        Target path for tests: /target  (TARGET_PATH)
        Number of test iterations to run: 1  (ITERATIONS)
        Random startup delay (s): 0  (STARTUP_DELAY)
        Random delay between iterations (s): 0  (RAND_THINK)
        Delete contents of target dir on startup: 0  (DELETE_FIRST)
        File size for fio benchmark: 500  (FIO_CAPACITY_MB)
        Runtime for individual fio tests (s): 120  (FIO_RUNTIME)
        Git repo to use for clone test: https://github.com/gluster/glusterfs.git  (CLONE_REPO)
Benchmark: clone
        Time to clone Git repository: 31.74 s
        Time to remove cloned files: 0.10 s
Benchmark: fio
        Max write bandwidth: 146 MiB/s
        Max read bandwidth: 475 MiB/s
        Write I/O latency: 0.045 ms
        Read I/O latency: 0.132 ms
        Max write throughput: 60155 IOPS
        Max read throughput: 64914 IOPS
Benchmark: kernel
        Time to untar linux kernel: 8.90 s
        Time to delete untar-ed files: 0.72 s
```

### Running in a Kubernetes cluster

The included [`fs-performance.yml`](fs-performance.yml) file is a Kubernetes Job
and associated PersistentVolumeClaim that permits testing particular classes of
storage.

By default, it will allocate from the cluster's default StorageClass, but this
can be changed by uncommenting and setting the StorageClassName within the PVC.

Once the file has been customized, it can be run via:

```
$ kubectl apply -f fs-performance.yml
...
```
