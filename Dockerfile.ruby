ARG RUBY_VERSION=3.3-alpine
FROM ruby:${RUBY_VERSION}

# script(1) and tput(1), for the test of colour on a terminal. The Alpine base
# has neither, and the test is skipped without them (as it is in CI's Alpine
# job, which does not use this image).
RUN apk add --no-cache util-linux ncurses

# Copy project files to /tmp (matching Packer workflow)
COPY spec /tmp/spec
COPY exe /tmp/exe
COPY docker/assets/.ashenv /tmp/.ashenv
COPY docker/assets/etc-paths /tmp/etc-paths
COPY docker/install-ruby.sh /tmp/install.sh

WORKDIR /root

# Run setup script (moves files from /tmp to final locations)
RUN chmod +x /tmp/install.sh && \
    sh -x /tmp/install.sh && \
    rm /tmp/install.sh

ENV PATH_HELPER_DOCKER_INSTANCE=true
ENV PATH_HELPER_EXECUTABLE=/root/exe/path_helper
ENTRYPOINT ["spec/shell_spec.sh"]
