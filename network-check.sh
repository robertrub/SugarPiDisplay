#!/usr/bin/env bash
# Advanced network health check for SugarPiDisplay
# Location: ~/SugarPiDisplay/network-check.sh
# - Prefer HEALTH URL passed as first arg or SUGARPI_HEALTH_URL env var
# - Fallback to ping 1.1.1.1
# - Retries with exponential backoff
# - Logs to journal via logger
# - Starts sugarpidisplay.service when network is validated

set -uo pipefail
IFS=$'\n\t'

TAG="sugarpidisplay-network-check"
MAIN_SERVICE="sugarpidisplay.service"
DEFAULT_PING_DEST="1.1.1.1"
PING_COUNT=1
PING_TIMEOUT=2        # seconds
CURL_TIMEOUT=5        # seconds
RETRIES=3

# Health URL: first arg overrides env var
HEALTH_URL="${1:-${SUGARPI_HEALTH_URL:-}}"

log() {
  # Use logger so messages end up in journal
  logger -t "${TAG}" "$*"
}

do_curl_check() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then
    if curl --fail --silent --show-error --max-time "${CURL_TIMEOUT}" "${url}" >/dev/null 2>&1; then
      return 0
    else
      return 1
    fi
  fi
  # If curl isn't available, fall back to ping
  return 2
}

do_ping_check() {
  local dest="${1:-$DEFAULT_PING_DEST}"
  if command -v ping >/dev/null 2>&1; then
    if ping -c "${PING_COUNT}" -W "${PING_TIMEOUT}" "${dest}" >/dev/null 2>&1; then
      return 0
    else
      return 1
    fi
  fi
  # No ping available
  return 2
}

# Attempt checks with retries and backoff
attempt=0
success=1
while [ $attempt -lt $RETRIES ]; do
  attempt=$((attempt + 1))
  log "Attempt ${attempt}/${RETRIES} to verify network..."

  if [ -n "${HEALTH_URL}" ]; then
    do_curl_check "${HEALTH_URL}"
    rc=$?
    if [ $rc -eq 0 ]; then
      log "HTTP check OK (${HEALTH_URL})"
      success=0
      break
    elif [ $rc -eq 2 ]; then
      log "curl not available; falling back to ping"
      do_ping_check
      rc=$?
      if [ $rc -eq 0 ]; then
        log "Ping check OK (fallback)"
        success=0
        break
      fi
    else
      log "HTTP check failed (${HEALTH_URL})"
    fi
  else
    do_ping_check
    rc=$?
    if [ $rc -eq 0 ]; then
      log "Ping check OK (${DEFAULT_PING_DEST})"
      success=0
      break
    elif [ $rc -eq 2 ]; then
      log "No curl or ping available to test network"
    else
      log "Ping check failed (${DEFAULT_PING_DEST})"
    fi
  fi

  # Backoff before next attempt (2, 4, 8 ... seconds)
  sleep_time=$((2 ** (attempt - 1) * 2))
  log "Network not ready; sleeping ${sleep_time}s before retry"
  sleep "${sleep_time}"
done

if [ $success -eq 0 ]; then
  log "Network detected. Ensuring ${MAIN_SERVICE} is running."
  if command -v systemctl >/dev/null 2>&1; then
    /bin/systemctl start "${MAIN_SERVICE}" >/dev/null 2>&1 || true
    /bin/systemctl is-active --quiet "${MAIN_SERVICE}" && log "${MAIN_SERVICE} is active" || log "Started ${MAIN_SERVICE} (or it will auto-restart)"
  fi
  exit 0
else
  log "Network check FAILED after ${RETRIES} attempts."
  # Do NOT forcibly stop the main service (some users prefer it to run offline).
  # Exiting non-zero signals systemd that the unit failed.
  exit 1
fi
