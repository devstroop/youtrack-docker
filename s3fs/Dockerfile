FROM alpine:3.19

RUN apk add --no-cache s3fs-fuse bash ca-certificates && \
    mkdir -p /opt/s3fs/bucket /tmp/cache

# Optional: create non-root user (will be used if UID/GID passed)
RUN addgroup -S s3fs && adduser -S s3fs -G s3fs

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV AWS_S3_URL="https://s3.us-east-1.amazonaws.com" \
    S3FS_ARGS="-o allow_other -o use_cache=/tmp/cache"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
