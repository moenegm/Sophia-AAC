#!/bin/sh
set -eu
case "${CONFIGURATION:-}" in
  *Release)
    if [ -d "${SRCROOT}/legacy" ]; then
      echo 'error: Release blocked: remove legacy/ before creating a TestFlight or App Store build.' >&2
      exit 1
    fi
    ;;
esac
