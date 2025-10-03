# YouTrack Docker with S3FS Backup

This Docker Compose setup runs JetBrains YouTrack with automated S3 backup synchronization using S3FS.

## Features

- 🚀 **YouTrack** - Latest version with persistent data storage
- 💾 **S3FS Integration** - Automatic backup sync to S3-compatible storage
- 🔄 **Health Checks** - Built-in monitoring for both services
- 🛡️ **Security** - Proper user permissions and credential handling
- ⚡ **Performance** - Optimized S3FS cache settings

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- AWS S3 bucket or S3-compatible storage (MinIO, Wasabi, etc.)
- AWS credentials with read/write access to the bucket

## Quick Start

1. **Clone and configure:**
   ```bash
   git clone <repository-url>
   cd youtrack-docker
   cp stack.env stack.env.local
   ```

2. **Edit `stack.env` with your settings:**
   ```bash
   # Update these values
   AWS_S3_BUCKET=your-bucket-name
   AWS_S3_ACCESS_KEY_ID=your-access-key
   AWS_S3_SECRET_ACCESS_KEY=your-secret-key
   AWS_S3_URL=https://s3.us-east-1.amazonaws.com
   ```

3. **Start services:**
   ```bash
   make up
   # or
   docker-compose up -d
   ```

4. **Access YouTrack:**
   Open http://localhost:8080 in your browser

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `YOUTRACK_VERSION` | YouTrack version tag | `2025.2.93511` |
| `YOUTRACK_PORT` | Port to expose YouTrack | `8080` |
| `AWS_S3_BUCKET` | S3 bucket name | Required |
| `AWS_S3_ACCESS_KEY_ID` | AWS access key | Required |
| `AWS_S3_SECRET_ACCESS_KEY` | AWS secret key | Required |
| `AWS_S3_URL` | S3 endpoint URL | `https://s3.us-east-1.amazonaws.com` |
| `S3FS_ARGS` | Additional s3fs mount options | See below |

### S3FS Mount Options

Default optimized settings:
```bash
S3FS_ARGS=-o allow_other -o use_cache=/tmp/cache -o max_stat_cache_size=100000 -o stat_cache_expire=900 -o multireq_max=5 -o parallel_count=10
```

**Common options:**
- `allow_other` - Allow all users to access mount
- `use_cache=/tmp/cache` - Enable local file caching
- `max_stat_cache_size=100000` - Cache up to 100k file metadata entries
- `stat_cache_expire=900` - Cache expires after 15 minutes
- `multireq_max=5` - Maximum parallel S3 requests
- `parallel_count=10` - Parallel multipart upload threads

### Using Non-AWS S3 Providers

**MinIO:**
```bash
AWS_S3_URL=https://minio.example.com
```

**Wasabi:**
```bash
AWS_S3_URL=https://s3.wasabisys.com
```

**DigitalOcean Spaces:**
```bash
AWS_S3_URL=https://nyc3.digitaloceanspaces.com
```

## Usage

### Using Makefile

```bash
make help              # Show available commands
make up                # Start all services
make down              # Stop all services
make restart           # Restart all services
make logs              # Show all logs
make logs-youtrack     # Show YouTrack logs only
make logs-s3fs         # Show S3FS logs only
make backup            # Create manual backup
make clean             # Stop and remove all containers
make rebuild           # Rebuild from scratch
```

### Using Docker Compose Directly

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart a specific service
docker-compose restart youtrack
```

## Architecture

### Service Dependencies

```
youtrack (starts first)
    ↓
    (health check waits for API ready)
    ↓
s3fs (starts after youtrack is healthy)
```

### Volume Mounts

**YouTrack Service:**
- `youtrack_data` → `/opt/youtrack/data` - Application data
- `youtrack_conf` → `/opt/youtrack/conf` - Configuration files
- `youtrack_logs` → `/opt/youtrack/logs` - Application logs
- `youtrack_backups` → `/opt/youtrack/backups` - Backup files

**S3FS Service:**
- `s3fs_bucket` → `/opt/s3fs/bucket` - Mounted S3 bucket
- `youtrack_backups` → `/data/youtrack_backups` (read-only) - Access to YouTrack backups
- `s3fs_cache` → `/tmp/cache` - Local cache for S3FS

## Backup Strategy

### Automatic Backups

YouTrack backups are automatically accessible to the S3FS service and can be synced to S3 storage.

### Manual Backup

```bash
# Create a backup
docker-compose exec youtrack /opt/youtrack/bin/youtrack.sh backup

# The backup will appear in the youtrack_backups volume
# and be accessible to S3FS for syncing
```

### Restore from Backup

1. Stop YouTrack:
   ```bash
   docker-compose stop youtrack
   ```

2. Copy backup from S3 to backup volume:
   ```bash
   docker-compose exec s3fs cp /opt/s3fs/bucket/backup.tar.gz /data/youtrack_backups/
   ```

3. Restore using YouTrack restore command

4. Restart services:
   ```bash
   docker-compose start youtrack
   ```

## Monitoring

### Health Checks

Both services have built-in health checks:

**YouTrack:**
- Checks API endpoint every 30s
- 60s startup grace period
- 3 retries before marked unhealthy

**S3FS:**
- Checks if S3 bucket is mounted every 30s
- 10s startup grace period
- 3 retries before marked unhealthy

### View Health Status

```bash
docker-compose ps
```

## Troubleshooting

### S3FS Mount Issues

1. **Check logs:**
   ```bash
   make logs-s3fs
   ```

2. **Verify credentials:**
   Ensure `AWS_S3_ACCESS_KEY_ID` and `AWS_S3_SECRET_ACCESS_KEY` are correct

3. **Test S3 connectivity:**
   ```bash
   docker-compose exec s3fs ping -c 3 s3.us-east-1.amazonaws.com
   ```

### YouTrack Not Starting

1. **Check logs:**
   ```bash
   make logs-youtrack
   ```

2. **Verify port availability:**
   ```bash
   lsof -i :8080
   ```

3. **Check disk space:**
   ```bash
   docker system df
   ```

### Permission Issues

If you encounter permission errors with S3FS:

1. Ensure `allow_other` is in `S3FS_ARGS`
2. Check that `/etc/fuse.conf` on host has `user_allow_other` enabled
3. Verify FUSE device is available: `ls -l /dev/fuse`

## Security Considerations

1. **Never commit `stack.env` with real credentials**
   - Use `stack.env.example` as template
   - Add `stack.env` to `.gitignore`

2. **Use IAM roles** when running on EC2/ECS instead of access keys

3. **Restrict S3 bucket access** with proper IAM policies

4. **Enable S3 bucket encryption** for data at rest

5. **Use HTTPS** for all S3 endpoints

## Performance Tuning

### For Large Instances

Increase memory limits in `docker-compose.yml`:

```yaml
services:
  youtrack:
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 2G
```

### For Slow Networks

Reduce cache expiration and parallel requests:

```bash
S3FS_ARGS=-o allow_other -o use_cache=/tmp/cache -o stat_cache_expire=1800 -o multireq_max=3
```

## License

[Your License Here]

## Support

For issues and questions:
- YouTrack Documentation: https://www.jetbrains.com/help/youtrack/
- S3FS Documentation: https://github.com/s3fs-fuse/s3fs-fuse

## Contributing

Contributions are welcome! Please submit pull requests or open issues for bugs and feature requests.
