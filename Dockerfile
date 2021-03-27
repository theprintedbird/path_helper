FROM ruby:2.7.0-alpine3.11

WORKDIR /root

ENV PATH_HELPER_DOCKER_INSTANCE=true

COPY exe/path_helper exe/path_helper
COPY spec spec

RUN chmod +x exe/path_helper && \
		chmod +x spec/shell_spec.sh && \
		./exe/path_helper --setup --no-lib && \
		cp -R spec/fixtures/moredirs/* ~/.config/paths

ENTRYPOINT ["spec/shell_spec.sh"]
