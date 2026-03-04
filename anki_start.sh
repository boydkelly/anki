#!/usr/bin/env bash

install() {
  python -m venv --system-site-packages "/usr/local/anki" &&
    echo "Installing/upgrading pip" &&
    "/usr/local/anki/bin/pip" install -q --no-cache-dir --upgrade pip &&
    echo "Installing/upgrading Anki..." &&
    "/usr/local/anki/bin/pip" install -q --no-cache-dir --upgrade --pre aqt[qt6]
}

uninstall() {
  echo "Uninstalling Anki..."
  find /usr/local/anki -mindepth 1 -exec rm -rvf {} +
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

# If arguments were passed, run them as a command
if [[ $# -gt 0 ]]; then
  exec "$@"
else
  exec "/usr/local/anki/bin/anki"
fi
