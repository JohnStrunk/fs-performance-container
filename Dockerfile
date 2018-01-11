FROM centos:7

RUN yum install -y epel-release && \
    yum install -y \
      fio \
    && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    useradd -M bench-runner && \
    mkdir /fio

USER bench-runner:bench-runner

COPY entry.sh /
COPY fio/*.fio /fio

VOLUME /target

ENTRYPOINT ["/entry.sh"]
