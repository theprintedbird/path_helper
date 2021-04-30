FROM ruby:2.7.0-alpine3.11

WORKDIR /root

ENV PATH_HELPER_DOCKER_INSTANCE=true

COPY spec spec
COPY docker/assets/.ashenv .

COPY exe/path_helper exe/path_helper
RUN chmod +x exe/path_helper && \
		chmod +x spec/shell_spec.sh && \
		./exe/path_helper --setup --no-lib --quiet && \
		cp -R spec/fixtures/moredirs/* ~/.config/paths && \
		echo "/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > /etc/paths

ENTRYPOINT ["spec/shell_spec.sh"]
