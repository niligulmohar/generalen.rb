FROM ruby:2.3

RUN mkdir -p /app/data
COPY ./ /app/
WORKDIR /app/data
RUN bundle install
CMD bundle exec /app/slackbot.rb