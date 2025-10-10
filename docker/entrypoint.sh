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

TARGET_GROUP="${APP_GROUP}"
EXISTING_GROUP_BY_GID="$(getent group | awk -F: -v PGID="${PGID}" '$3 == PGID {print $1; exit}')"

if [ -n "${EXISTING_GROUP_BY_GID}" ] && [ "${EXISTING_GROUP_BY_GID}" != "${APP_GROUP}" ]; then
  TARGET_GROUP="${EXISTING_GROUP_BY_GID}"
fi

# Create or update group with desired PGID
if getent group "${TARGET_GROUP}" >/dev/null 2>&1; then
  CURRENT_GID="$(getent group "${TARGET_GROUP}" | cut -d: -f3)"
  if [ "${CURRENT_GID}" != "${PGID}" ]; then
    groupmod -o -g "${PGID}" "${TARGET_GROUP}"
  fi
else
  if [ -n "${EXISTING_GROUP_BY_GID}" ]; then
    TARGET_GROUP="${EXISTING_GROUP_BY_GID}"
  else
    addgroup -g "${PGID}" "${TARGET_GROUP}"
  fi
fi

# Create or update user with desired PUID
if getent passwd "${APP_USER}" >/dev/null 2>&1; then
  CURRENT_UID="$(getent passwd "${APP_USER}" | cut -d: -f3)"
  if [ "${CURRENT_UID}" != "${PUID}" ]; then
    usermod -o -u "${PUID}" "${APP_USER}"
  fi
  usermod -g "${TARGET_GROUP}" "${APP_USER}"
else
  adduser -D -H -G "${TARGET_GROUP}" -u "${PUID}" "${APP_USER}"
fi

# Ensure application files are owned by the runtime user
chown -R "${APP_USER}:${TARGET_GROUP}" /app

exec su-exec "${APP_USER}:${TARGET_GROUP}" "$@"
