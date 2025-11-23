ARG RUBY_VERSION=3.3-alpine
FROM ruby:${RUBY_VERSION}

# Copy project files to /tmp (matching Packer workflow)
COPY spec /tmp/spec
COPY exe /tmp/exe
COPY docker/assets/.ashenv /tmp/.ashenv
COPY docker/assets/etc-paths /tmp/etc-paths
COPY docker/install.sh /tmp/install.sh

WORKDIR /root

# Run setup script (moves files from /tmp to final locations)
RUN chmod +x /tmp/install.sh && \
    sh -x /tmp/install.sh && \
    rm /tmp/install.sh

ENV PATH_HELPER_DOCKER_INSTANCE=true
ENTRYPOINT ["spec/shell_spec.sh"]
