#!/usr/bin/env bash

# Tell uv where its project environment lives
export UV_PROJECT_ENVIRONMENT="/usr/local/anki"
export UV_LINK_MODE=copy
export QSG_RHI_BACKEND=opengl
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-features=Vulkan"

install() {
  # Change to the app directory where pyproject.toml lives
  cd /app || exit 1

  # 1. If uv.lock doesn't exist, generate it directly from the container's environment
  if [[ ! -f "uv.lock" ]]; then
    echo "No lockfile found. Generating a container-optimized uv.lock..."
    uv lock
  fi

  # 2. Sync the environment. We drop --frozen so uv can safely use
  # the newly generated or existing lockfile.
  echo "Syncing Anki project environment with Fedora system packages..."
  uv sync --no-cache
}

uninstall() {
  echo "Uninstalling Anki..."
  if [ -d "/usr/local/anki" ]; then
    rm -rf /usr/local/anki/* /usr/local/anki/.[!.]*
    echo "Uninstalled successfully."
  fi
}

case "$1" in
install)
  install
  exit 0
  ;;
uninstall)
  uninstall
  exit 0
  ;;
esac

if [[ ! -x "/usr/local/anki/bin/anki" ]]; then
  install
fi

if [[ $# -gt 0 ]]; then
  exec "$@"
else
  exec "/usr/local/anki/bin/anki"
fi
