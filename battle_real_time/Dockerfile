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

# Stage 2: Minimal runtime image
FROM alpine:3.21 AS runner

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/battle_real_time ./

ENV PHX_SERVER=true
ENV PORT=4000

EXPOSE 4000

CMD ["bin/battle_real_time", "start"]
