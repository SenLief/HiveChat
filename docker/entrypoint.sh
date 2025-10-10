#!/bin/sh
set -eu

APP_USER=appuser
APP_GROUP=appgroup

PUID="${PUID:-}"
PGID="${PGID:-}"

if [ -z "${PUID}" ] || [ -z "${PGID}" ]; then
  echo "Error: PUID and PGID environment variables must be provided." >&2
  exit 1
fi

# Ensure timezone configuration
if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
fi

# Create or update group with desired PGID
if getent group "${APP_GROUP}" >/dev/null 2>&1; then
  CURRENT_GID="$(getent group "${APP_GROUP}" | cut -d: -f3)"
  if [ "${CURRENT_GID}" != "${PGID}" ]; then
    groupmod -o -g "${PGID}" "${APP_GROUP}"
  fi
else
  addgroup -g "${PGID}" "${APP_GROUP}"
fi

# Create or update user with desired PUID
if getent passwd "${APP_USER}" >/dev/null 2>&1; then
  CURRENT_UID="$(getent passwd "${APP_USER}" | cut -d: -f3)"
  if [ "${CURRENT_UID}" != "${PUID}" ]; then
    usermod -o -u "${PUID}" "${APP_USER}"
  fi
  usermod -g "${APP_GROUP}" "${APP_USER}"
else
  adduser -D -H -G "${APP_GROUP}" -u "${PUID}" "${APP_USER}"
fi

# Ensure application files are owned by the runtime user
chown -R "${APP_USER}:${APP_GROUP}" /app

exec su-exec "${APP_USER}:${APP_GROUP}" "$@"
