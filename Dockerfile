FROM centos:7

RUN yum install -y \
      bash \
      fio \
      git \
      time \
      wget \
      xz \
    && \
    yum update -y && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    useradd bench-runner

RUN wget --progress=dot:giga -O kernel.tar.xz https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.1.51.tar.xz && \
    chmod 644 /kernel.tar.xz && \
    mkdir -p /target && \
    chmod 777 /target

COPY entry.sh /
RUN chmod 755 /entry.sh

USER bench-runner:bench-runner

ENTRYPOINT ["/entry.sh"]
