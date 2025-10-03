#!/bin/bash
set -euo pipefail

# Validate required environment variables
: "${AWS_S3_BUCKET:?AWS_S3_BUCKET is required}"
: "${AWS_S3_ACCESS_KEY_ID:?AWS_S3_ACCESS_KEY_ID is required}"
: "${AWS_S3_SECRET_ACCESS_KEY:?AWS_S3_SECRET_ACCESS_KEY is required}"

# Trap to ensure cleanup on exit
cleanup() {
    echo "Unmounting S3 bucket..."
    fusermount -u /opt/s3fs/bucket 2>/dev/null || umount /opt/s3fs/bucket 2>/dev/null || true
}
trap cleanup EXIT TERM INT

# Create credentials file securely
CREDS=/tmp/passwd-s3fs
printf '%s:%s' "$AWS_S3_ACCESS_KEY_ID" "$AWS_S3_SECRET_ACCESS_KEY" > "$CREDS"
chmod 600 "$CREDS"

# Prepare mount point
MOUNT_POINT=/opt/s3fs/bucket
mkdir -p "$MOUNT_POINT"

# Build s3fs arguments (use -f for foreground mode)
ARGS=("$AWS_S3_BUCKET" "$MOUNT_POINT" "-f" "-o" "passwd_file=$CREDS")

# Add URL if provided
if [[ -n "${AWS_S3_URL:-}" ]]; then
    ARGS+=("-o" "url=${AWS_S3_URL}")
fi

# Parse additional S3FS arguments
if [[ -n "${S3FS_ARGS:-}" ]]; then
    # shellcheck disable=SC2206
    EXTRA_ARGS=($S3FS_ARGS)
    ARGS+=("${EXTRA_ARGS[@]}")
fi

# Add recommended defaults if not already present
if [[ ! "${S3FS_ARGS:-}" =~ "nonempty" ]]; then
    ARGS+=("-o" "nonempty")
fi

echo "Mounting S3 bucket: $AWS_S3_BUCKET at $MOUNT_POINT"
echo "Using URL: ${AWS_S3_URL:-default}"

# Execute s3fs in foreground mode (-f flag)
exec s3fs "${ARGS[@]}"
