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
# if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
#   ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
#   echo "${TZ}" > /etc/timezone
# fi

TARGET_GROUP="${APP_GROUP}"
TARGET_USER="${APP_USER}"
EXISTING_GROUP_BY_GID="$(getent group | awk -F: -v PGID="${PGID}" '$3 == PGID {print $1; exit}')"
EXISTING_USER_BY_UID="$(getent passwd | awk -F: -v PUID="${PUID}" '$3 == PUID {print $1; exit}')"

if [ -n "${EXISTING_GROUP_BY_GID}" ] && [ "${EXISTING_GROUP_BY_GID}" != "${APP_GROUP}" ]; then
  TARGET_GROUP="${EXISTING_GROUP_BY_GID}"
fi

if [ -n "${EXISTING_USER_BY_UID}" ] && [ "${EXISTING_USER_BY_UID}" != "${APP_USER}" ]; then
  TARGET_USER="${EXISTING_USER_BY_UID}"
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
if getent passwd "${TARGET_USER}" >/dev/null 2>&1; then
  CURRENT_UID="$(getent passwd "${TARGET_USER}" | cut -d: -f3)"
  if [ "${CURRENT_UID}" != "${PUID}" ]; then
    if [ "${TARGET_USER}" = "${APP_USER}" ]; then
      usermod -o -u "${PUID}" "${TARGET_USER}"
    else
      echo "Error: user ${TARGET_USER} already exists with UID ${CURRENT_UID}, which conflicts with requested PUID ${PUID}." >&2
      exit 1
    fi
  fi

  if [ "${TARGET_USER}" = "${APP_USER}" ]; then
    usermod -g "${TARGET_GROUP}" "${TARGET_USER}"
  else
    USER_GROUPS="$(id -nG "${TARGET_USER}" 2>/dev/null || true)"
    if ! printf '%s\n' "${USER_GROUPS}" | tr ' ' '\n' | grep -qx "${TARGET_GROUP}"; then
      usermod -a -G "${TARGET_GROUP}" "${TARGET_USER}"
    fi
  fi
else
  adduser -D -H -G "${TARGET_GROUP}" -u "${PUID}" "${TARGET_USER}"
fi

# Ensure application files are owned by the runtime user
chown -R "${TARGET_USER}:${TARGET_GROUP}" /app

exec su-exec "${TARGET_USER}:${TARGET_GROUP}" "$@"
