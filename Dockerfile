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

ARG builddate="(unknown)"
ARG version="(unknown)"
LABEL org.label-schema.build-date="${builddate}"
LABEL org.label-schema.description="File system benchmarking container"
LABEL org.label-schema.license="AGPL 3"
LABEL org.label-schema.name="fs-performance"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.vcs-ref="${version}"
LABEL org.label-schema.vcs-url="https://github.com/JohnStrunk/fs-performance-container"
LABEL org.label-schema.vendor="John Strunk"
LABEL org.label-schema.version="${version}"
