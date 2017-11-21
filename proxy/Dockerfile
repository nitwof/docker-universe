FROM elixir:1.5.2-alpine
MAINTAINER dsinelnikov96@gmail.com

ENV MIX_ENV=prod
ENV APP_HOME=/app

RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY . $APP_HOME
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get
RUN mix compile

CMD ["mix", "run", "--no-halt"]
