FROM alpine:3.18

RUN apk add --no-cache \
    s3fs-fuse \
    ca-certificates \
    bash \
    && mkdir -p /opt/s3fs/bucket /tmp/cache

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]