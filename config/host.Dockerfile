FROM ruby:3.1.2

ENV RAILS_ENV=production

# 2. 提前升级镜像中的 bundler 版本，使其与你的 Gemfile.lock (2.3.7) 一致
# RUN gem install bundler:2.3.7
RUN bundle config mirror.https://rubygems.org https://mirrors.tuna.tsinghua.edu.cn/rubygems

RUN mkdir /mangosteen
WORKDIR /mangosteen
ADD Gemfile /mangosteen
ADD Gemfile.lock /mangosteen
ADD vendor/cache /mangosteen/vendor/cache
RUN bundle config set --local without 'development test'
RUN bundle install --local

ADD mangosteen-*.tar.gz ./
ENTRYPOINT ["bundle", "exec", "puma"]
