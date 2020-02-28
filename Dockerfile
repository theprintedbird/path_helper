FROM ruby:2.7.0-alpine3.11

COPY . .

RUN bundle install --retry 5 --jobs 20

