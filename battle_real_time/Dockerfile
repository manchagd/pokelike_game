# Stage 1: Build the Elixir release
FROM hexpm/elixir:1.18.4-erlang-26.2.5.13-alpine-3.21.3 AS builder

WORKDIR /app

ENV MIX_ENV=prod

# Install build tools
RUN mix local.hex --force && mix local.rebar --force

# Fetch dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Compile the application
COPY config config/
COPY lib lib/
COPY priv priv/

RUN mix compile
RUN mix release

# Stage 2: Development image — keeps mix/elixir for running tasks
FROM hexpm/elixir:1.18.4-erlang-26.2.5.13-alpine-3.21.3 AS dev

WORKDIR /app

ENV MIX_ENV=dev

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get
RUN mix deps.compile

COPY config config/
COPY lib lib/
COPY priv priv/

RUN mix compile

EXPOSE 4000

CMD ["mix", "phx.server"]

# Stage 3: Minimal runtime image (production)
FROM alpine:3.21 AS runner

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/battle_real_time ./

ENV PHX_SERVER=true
ENV PORT=4000

EXPOSE 4000

CMD ["bin/battle_real_time", "start"]
