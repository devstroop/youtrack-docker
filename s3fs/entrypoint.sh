#!/bin/bash
set -euo pipefail

: "${AWS_S3_BUCKET:?AWS_S3_BUCKET is required}"
: "${AWS_S3_ACCESS_KEY_ID:?AWS_S3_ACCESS_KEY_ID is required}"
: "${AWS_S3_SECRET_ACCESS_KEY:?AWS_S3_SECRET_ACCESS_KEY is required}"

# Credentials file for s3fs
CREDS=/tmp/passwd-s3fs
printf '%s:%s' "$AWS_S3_ACCESS_KEY_ID" "$AWS_S3_SECRET_ACCESS_KEY" > "$CREDS"
chmod 600 "$CREDS"

# Adjust UID/GID if provided and numeric
if [[ -n "${UID:-}" && -n "${GID:-}" && "$UID" =~ ^[0-9]+$ && "$GID" =~ ^[0-9]+$ ]]; then
  if ! getent group s3fs >/dev/null 2>&1; then addgroup -S s3fs || true; fi
  if id s3fs >/dev/null 2>&1; then
    deluser s3fs || true
  fi
  addgroup -g "$GID" -S s3fsgroup || true
  adduser -S -D -u "$UID" -G s3fsgroup s3fsuser || true
  chown -R "$UID":"$GID" /opt/s3fs /tmp/cache
  RUN_USER=s3fsuser
else
  RUN_USER=root
fi

MOUNT_POINT=/opt/s3fs/bucket
mkdir -p "$MOUNT_POINT"

ARGS=("$AWS_S3_BUCKET" "$MOUNT_POINT" "-o" "passwd_file=$CREDS")

# Pass custom URL if provided (non-AWS or custom endpoint)
if [[ -n "${AWS_S3_URL:-}" ]]; then
  ARGS+=("-o" "url=${AWS_S3_URL}")
fi

# Split S3FS_ARGS into array if set
if [[ -n "${S3FS_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA_ARGS=($S3FS_ARGS)
  ARGS+=("${EXTRA_ARGS[@]}")
fi

echo "Mounting bucket $AWS_S3_BUCKET at $MOUNT_POINT"
# Use gosu/su-exec if installed to drop privileges (not installed by default)
if command -v su-exec >/dev/null 2>&1 && [ "$RUN_USER" != root ]; then
  su-exec "$RUN_USER" s3fs "${ARGS[@]}"
else
  s3fs "${ARGS[@]}"
fi

# Keep container alive if mount succeeds
exec tail -f /dev/null
