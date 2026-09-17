FROM ruby:3.1.2-slim

ENV RAILS_ENV=production
RUN mkdir /mangosteen
RUN bundle config mirror.https://rubygems.org https://mirrors.tuna.tsinghua.edu.cn/rubygems
WORKDIR /mangosteen
ADD Gemfile /mangosteen
ADD Gemfile.lock /mangosteen
ADD vendor/cache /mangosteen/vendor/cache
RUN bundle config set --local without 'development test'
RUN bundle install --local

ADD mangosteen-*.tar.gz ./
ENTRYPOINT ["bundle", "exec", "puma"]
