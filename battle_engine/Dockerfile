FROM ruby:4.0.1-alpine

RUN apk add --no-cache build-base postgresql-dev

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

CMD ["ruby", "boot.rb"]
