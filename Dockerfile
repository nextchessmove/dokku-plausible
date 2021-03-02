FROM plausible/analytics

CMD \
  export CLICKHOUSE_DATABASE_URL=http://${DOKKU_CLICKHOUSE_PLAUSIBLE_ENV_CLICKHOUSE_USER}:${DOKKU_CLICKHOUSE_PLAUSIBLE_ENV_CLICKHOUSE_PASSWORD}@${DOKKU_CLICKHOUSE_PLAUSIBLE_PORT_8123_TCP_ADDR}:${DOKKU_CLICKHOUSE_PLAUSIBLE_PORT_8123_TCP_PORT}/${DOKKU_CLICKHOUSE_PLAUSIBLE_ENV_CLICKHOUSE_DB} && \
  sleep 10 && \
  /entrypoint.sh db createdb && \
  /entrypoint.sh db migrate && \
  /entrypoint.sh db init-admin && \
  /entrypoint.sh run
