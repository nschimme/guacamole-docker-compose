#!/bin/sh

# Get the project name from the container labels (e.g., COMPOSE_PROJECT_NAME)
PROJECT_NAME=$(docker inspect "$(hostname)" \
  --format '{{ index .Config.Labels "com.docker.compose.project" }}')

if [ -z "$PROJECT_NAME" ]; then
  echo "Unable to detect Docker Compose project name. Exiting."
  exit 1
fi

echo "Detected Compose project: $PROJECT_NAME"

while true; do
  # Get all container names in this compose project
  containers=$(docker ps --filter "label=com.docker.compose.project=$PROJECT_NAME" --format '{{.Names}}')

  for container in $containers; do
    # Skip containers without a health check
    if ! docker inspect -f '{{.State.Health.Status}}' "$container" >/dev/null 2>&1; then
      continue
    fi

    status=$(docker inspect -f '{{.State.Health.Status}}' "$container")

    if [ "$status" = "unhealthy" ]; then
      echo "$(date): Restarting unhealthy container: $container"
      docker restart "$container"
    fi
  done

  sleep 30
done

