#!/bin/bash
set -e

# Check required environment variables
if [ -z "$AWS_S3_BUCKET" ] || [ -z "$AWS_S3_ACCESS_KEY_ID" ] || [ -z "$AWS_S3_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS_S3_BUCKET, AWS_S3_ACCESS_KEY_ID, and AWS_S3_SECRET_ACCESS_KEY must be set"
    exit 1
fi

# Create credentials file
echo "${AWS_S3_ACCESS_KEY_ID}:${AWS_S3_SECRET_ACCESS_KEY}" > /tmp/passwd-s3fs
chmod 600 /tmp/passwd-s3fs

# Default S3FS arguments if not provided
S3FS_ARGS=${S3FS_ARGS:--o allow_other -o use_cache=/tmp/cache}

# Mount S3 bucket
echo "Mounting S3 bucket: ${AWS_S3_BUCKET} to /opt/s3fs/bucket"
s3fs "${AWS_S3_BUCKET}" /opt/s3fs/bucket \
    -o passwd_file=/tmp/passwd-s3fs \
    -o url=${AWS_S3_URL} \
    ${S3FS_ARGS}

# Keep container running
echo "S3FS mounted successfully"
tail -f /dev/null