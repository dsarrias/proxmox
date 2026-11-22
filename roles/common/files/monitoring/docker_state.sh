#!/bin/bash
# Writes container status, health and restart count for node_exporter's textfile collector (cAdvisor doesn't expose them)
# Usage: docker_state.sh <textfile directory>
OUT="$1/docker_state.prom"

{
  echo "# HELP docker_container_info Container status and health check state, always 1."
  echo "# TYPE docker_container_info gauge"
  echo "# HELP docker_container_restart_count Restarts done by the Docker restart policy since the container was created."
  echo "# TYPE docker_container_restart_count counter"
  docker inspect --format '{{slice .Name 1}} {{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} {{.RestartCount}} {{.Config.Image}}' $(docker ps -aq) |
    awk '{
      printf "docker_container_info{name=\"%s\",status=\"%s\",health=\"%s\",image=\"%s\"} 1\n", $1, $2, $3, $5
      restarts = restarts sprintf("docker_container_restart_count{name=\"%s\"} %s\n", $1, $4)
    } END { printf "%s", restarts }'
} > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
