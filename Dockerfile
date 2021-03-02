FROM plausible/analytics

CMD \
  sleep 10 && \
  /entrypoint.sh db createdb && \
  /entrypoint.sh db migrate && \
  /entrypoint.sh db init-admin && \
  /entrypoint.sh run
