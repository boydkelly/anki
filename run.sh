#!/bin/bash
podman run --rm --name anki -it \
  --security-opt label=disable \
  --net host \
  anki bash
