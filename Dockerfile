FROM alpine:3.20

# Only required package: bash (busybox provides df, uptime, ping, etc.)
RUN apk add --no-cache bash

WORKDIR /app
COPY app/ /app/
RUN chmod +x /app/*.sh \
    && ln -s /app/diagnostic.sh /usr/local/bin/diagnostic \
    && adduser -D -H appuser

# Run as non-root
USER appuser

ENTRYPOINT ["/app/diagnostic.sh"]
CMD ["help"]
