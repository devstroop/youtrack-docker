FROM alpine:3.19

RUN apk add --no-cache \
    s3fs-fuse \
    bash \
    ca-certificates \
    su-exec \
    && mkdir -p /opt/s3fs/bucket /tmp/cache

# Create non-root user
RUN addgroup -g 1000 -S s3fs && \
    adduser -u 1000 -S s3fs -G s3fs

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV AWS_S3_URL="https://s3.us-east-1.amazonaws.com" \
    S3FS_ARGS="-o allow_other -o use_cache=/tmp/cache -o max_stat_cache_size=100000"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
