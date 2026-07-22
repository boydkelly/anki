#!/usr/bin/env bash

# Tell uv where its project environment lives
export UV_PROJECT_ENVIRONMENT="/usr/local/anki"
export UV_LINK_MODE=copy
export QSG_RHI_BACKEND=opengl
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-features=Vulkan"

install() {
  # 1. If venv doesn't exist, create it
  if [[ ! -x "/usr/local/anki/bin/python3" ]]; then
    echo "Creating fresh virtual environment..."
    uv venv --python /usr/bin/python3 /usr/local/anki
  fi

  # 2. Install/upgrade Anki and Aqt using uv
  echo "Installing Anki and Aqt..."
  if [[ $# -gt 0 ]]; then
    uv pip install --python /usr/local/anki --no-cache "$@"
  else
    uv pip install --python /usr/local/anki --no-cache anki aqt
  fi
}

uninstall() {
  echo "Uninstalling Anki..."
  if [[ -x "/usr/local/anki/bin/python3" ]]; then
    uv pip uninstall --python /usr/local/anki anki aqt
  fi
  # Remove residual binaries or files if any
  rm -f /usr/local/anki/bin/anki /usr/local/anki/bin/aqt 2>/dev/null
  echo "Uninstalled successfully."
}

case "$1" in
install)
  shift
  install "$@"
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
