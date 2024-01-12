# syntax = docker/dockerfile:1

# Keep in step with .ruby-version and the `ruby` line in the Gemfile.
ARG RUBY_VERSION=3.2.2

FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"


# ---- build stage: compilers and headers stay out of the final image --------
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

# SECRET_KEY_BASE_DUMMY lets assets compile without the real master key.
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# ---- runtime ---------------------------------------------------------------
FROM base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl postgresql-client && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Non-root runtime user owning only what it has to write to.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

EXPOSE 3000

# /up touches neither the database nor Twilio, so it answers as soon as Puma
# is accepting connections.
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=5 \
  CMD curl -fsS http://localhost:3000/up || exit 1

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server"]
