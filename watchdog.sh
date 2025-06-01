#!/bin/sh

# Find any container with the compose label to get the project name
container_id=$(docker ps --filter "label=com.docker.compose.project" --format '{{.ID}}' | head -n 1)

if [ -z "$container_id" ]; then
  echo "No running Docker Compose containers found. Exiting."
  exit 1
fi

# Extract project name from that container's label
PROJECT_NAME=$(docker inspect "$container_id" \
  --format '{{ index .Config.Labels "com.docker.compose.project" }}')

if [ -z "$PROJECT_NAME" ]; then
  echo "Unable to detect Docker Compose project name. Exiting."
  exit 1
fi

echo "Detected Compose project: $PROJECT_NAME"

while true; do
  containers=$(docker ps --filter "label=com.docker.compose.project=$PROJECT_NAME" --format '{{.Names}}')

  for container in $containers; do
    if ! docker inspect -f '{{.State.Health.Status}}' "$container" >/dev/null 2>&1; then
      continue
    fi

    status=$(docker inspect -f '{{.State.Health.Status}}' "$container")

    if [ "$status" = "unhealthy" ]; then
      echo "$(date): Container $container is unhealthy. Restarting entire Compose project: $PROJECT_NAME"
      docker compose -p "$PROJECT_NAME" restart
    fi
  done

  sleep 30
done

