FROM ruby:3.3.8-alpine AS builder

RUN apk update && apk upgrade && apk add --update --no-cache \
  build-base \
  curl-dev \
  libffi-dev \
  linux-headers \
  perl-yaml-libyaml \
  postgresql-dev \
  tzdata

ARG RAILS_ROOT=/usr/src/app/
WORKDIR $RAILS_ROOT

COPY Gemfile* $RAILS_ROOT
RUN bundle install

### BUILD STEP DONE ###

FROM ruby:3.3.8-alpine

ARG RAILS_ROOT=/usr/src/app/

# available: https://pkgs.alpinelinux.org/packages
RUN apk update && apk upgrade && apk add --update --no-cache \
  bash \
  build-base \
  curl \
  imagemagick \
  nodejs \
  npm \
  tzdata \
  vim \
  && rm -rf /var/cache/apk/*

WORKDIR $RAILS_ROOT

COPY . .
RUN npm install --global npm
RUN npm install
RUN npm run build && npm run build:css

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bin/rails", "s", "-b", "0.0.0.0"]
