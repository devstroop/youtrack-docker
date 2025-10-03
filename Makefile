.PHONY: help setup up down restart logs logs-youtrack logs-s3fs backup clean rebuild

help:
	@echo "Available commands:"
	@echo "  make setup           - Setup permissions for bind mounts"
	@echo "  make up              - Start all services"
	@echo "  make down            - Stop all services"
	@echo "  make restart         - Restart all services"
	@echo "  make logs            - Show logs for all services"
	@echo "  make logs-youtrack   - Show logs for YouTrack service"
	@echo "  make logs-s3fs       - Show logs for S3FS service"
	@echo "  make backup          - Create YouTrack backup"
	@echo "  make clean           - Stop and remove all containers, networks"
	@echo "  make rebuild         - Rebuild and restart all services"

setup:
	@chmod +x setup-permissions.sh
	@./setup-permissions.sh

up:
	docker-compose up -d

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

logs-youtrack:
	docker-compose logs -f youtrack

logs-s3fs:
	docker-compose logs -f s3fs

backup:
	docker-compose exec youtrack /opt/youtrack/bin/youtrack.sh backup

clean:
	docker-compose down -v

rebuild:
	docker-compose down
	docker-compose build --no-cache
	docker-compose up -d
