#!/bin/sh
set -e

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
APP_USER="${APP_USER:-hivechat}"
APP_GROUP="${APP_GROUP:-hivechat}"

# resolve or create group matching PGID
GROUP_FROM_GID="$(getent group | awk -F: -v gid="$PGID" '$3==gid {print $1; exit}')"
if [ -n "$GROUP_FROM_GID" ]; then
  RUNTIME_GROUP="$GROUP_FROM_GID"
else
  if getent group "$APP_GROUP" >/dev/null 2>&1; then
    EXISTING_GID="$(getent group "$APP_GROUP" | cut -d: -f3)"
    if [ "$EXISTING_GID" = "$PGID" ]; then
      RUNTIME_GROUP="$APP_GROUP"
    else
      RUNTIME_GROUP="hcgroup_$PGID"
      if ! getent group "$RUNTIME_GROUP" >/dev/null 2>&1; then
        addgroup -g "$PGID" "$RUNTIME_GROUP"
      fi
    fi
  else
    addgroup -g "$PGID" "$APP_GROUP"
    RUNTIME_GROUP="$APP_GROUP"
  fi
fi

# resolve or create user matching PUID
USER_FROM_UID="$(getent passwd | awk -F: -v uid="$PUID" '$3==uid {print $1; exit}')"
if [ -n "$USER_FROM_UID" ]; then
  RUNTIME_USER="$USER_FROM_UID"
else
  if getent passwd "$APP_USER" >/dev/null 2>&1; then
    EXISTING_UID="$(getent passwd "$APP_USER" | cut -d: -f3)"
    if [ "$EXISTING_UID" = "$PUID" ]; then
      RUNTIME_USER="$APP_USER"
    else
      RUNTIME_USER="hcuser_$PUID"
      if ! getent passwd "$RUNTIME_USER" >/dev/null 2>&1; then
        adduser -D -H -u "$PUID" -G "$RUNTIME_GROUP" "$RUNTIME_USER"
      fi
    fi
  else
    adduser -D -H -u "$PUID" -G "$RUNTIME_GROUP" "$APP_USER"
    RUNTIME_USER="$APP_USER"
  fi
fi

# ensure user is member of runtime group when both exist
if id -u "$RUNTIME_USER" >/dev/null 2>&1; then
  if ! id -nG "$RUNTIME_USER" | tr ' ' '\n' | grep -qx "$RUNTIME_GROUP"; then
    addgroup "$RUNTIME_USER" "$RUNTIME_GROUP" >/dev/null 2>&1 || true
  fi
fi

for path in /app /app/.next /app/.next/static /app/public; do
  if [ -e "$path" ]; then
    chown -R "$PUID":"$PGID" "$path"
  fi
done

exec su-exec "$PUID":"$PGID" "$@"
