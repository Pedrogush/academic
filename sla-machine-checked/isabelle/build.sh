#!/bin/bash
# Build the SLA session.
#
# Isabelle2025-2, installed rootlessly into $HOME (no sudo).  The session's
# parent is plain HOL, whose heap image SHIPS PREBUILT with the distribution,
# so nothing beyond the SLA theories themselves has to be compiled.
#
# Resource caps are deliberate: this machine has 4 cores / 7 GB RAM.

set -u
ISABELLE=${ISABELLE:-$HOME/Isabelle2025-2/bin/isabelle}
DIR="$(cd "$(dirname "$0")" && pwd)"

exec nice -n 15 timeout 3600 "$ISABELLE" build \
    -d "$DIR" \
    -o threads=2 \
    -o document=false \
    -v \
    SLA
