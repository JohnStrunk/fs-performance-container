FROM centos:7

RUN yum install -y \
      bash \
      fio \
      git \
      time \
      xz \
    && \
    yum update -y && \
    yum clean all && \
    rm -rf /var/cache/yum

#-- Include a kernel image for the kernel untar test
RUN curl -sSL https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.1.51.tar.xz > /kernel.tar.xz && \
    chmod 644 /kernel.tar.xz

#-- CentOS doesn't ship the jq package
RUN curl -sSL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > /usr/local/bin/jq && \
    chmod a+x /usr/local/bin/jq

#-- /target is where the fs to test should be mounted
RUN mkdir -p /target && \
    chmod 777 /target
VOLUME /target

#-- Set up the benchmark script
COPY entry.sh /
RUN chmod 755 /entry.sh
ENTRYPOINT ["/entry.sh"]

#-- Run as a non-root user
RUN useradd bench-runner
USER bench-runner:bench-runner

ARG builddate="(unknown)"
ARG version="(unknown)"
LABEL org.label-schema.build-date="${builddate}"
LABEL org.label-schema.description="File system benchmarking container"
LABEL org.label-schema.license="AGPL-3.0"
LABEL org.label-schema.name="fs-performance"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.vcs-ref="${version}"
LABEL org.label-schema.vcs-url="https://github.com/JohnStrunk/fs-performance-container"
LABEL org.label-schema.vendor="John Strunk"
LABEL org.label-schema.version="${version}"
