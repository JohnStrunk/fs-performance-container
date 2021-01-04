# fs-performance-container

![Tests](https://github.com/JohnStrunk/fs-performance-container/workflows/Tests/badge.svg?branch=master)

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
persistentvolumeclaim/fs-perf-target created
job.batch/fs-performance created

$ kubectl get job,po,pvc
NAME                       DESIRED   SUCCESSFUL   AGE
job.batch/fs-performance   1         0            2m

NAME                       READY   STATUS    RESTARTS   AGE
pod/fs-performance-xkvnh   1/1     Running   0          2m

NAME                                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/fs-perf-target   Bound    pvc-9d7edb92-727d-11e9-b69a-029a5a55534e   1Gi        RWO            gp2            2m
```

After completion of the batch job, the results can be retrieved:

```
$ kubectl get job,po
NAME                       DESIRED   SUCCESSFUL   AGE
job.batch/fs-performance   1         1            19m

NAME                       READY   STATUS      RESTARTS   AGE
pod/fs-performance-xkvnh   0/1     Completed   0          19m

$ kubectl logs fs-performance-xkvnh
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
        Time to clone Git repository: 17.64 s
        Time to remove cloned files: 0.08 s
Benchmark: fio
        Max write bandwidth: 120 MiB/s
        Max read bandwidth: 120 MiB/s
        Write I/O latency: 0.572 ms
        Read I/O latency: 0.551 ms
        Max write throughput: 3085 IOPS
        Max read throughput: 3071 IOPS
Benchmark: kernel
        Time to untar linux kernel: 13.23 s
        Time to delete untar-ed files: 0.95 s
```

Clean up:

```
$ kubectl delete -f fs-performance.yml
persistentvolumeclaim "fs-perf-target" deleted
job.batch "fs-performance" deleted
```
