FROM fedora:27

RUN dnf install -y \
      bash \
      fio \
      git \
      maven \
    && dnf clean all && \
    rm -rf /var/cache/yum && \
    useradd bench-runner

RUN mkdir -p /target && \
    chmod 777 /target

USER bench-runner:bench-runner

COPY entry.sh /

ENTRYPOINT ["/entry.sh"]
