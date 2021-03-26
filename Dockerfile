FROM ruby:2.7.0-alpine3.11

WORKDIR /root
COPY Gemfile /root/Gemfile
COPY path_helper.gemspec /root/path_helper.gemspec

ENV PATH_HELPER_DOCKER_INSTANCE=true

RUN bundle install --retry 5 --jobs 20

