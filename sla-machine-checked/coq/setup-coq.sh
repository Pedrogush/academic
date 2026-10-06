#!/usr/bin/env bash
# Rootless bootstrap of Coq 8.18 (no sudo required).
#
# Downloads the Ubuntu .deb packages and unpacks them into a local prefix,
# then writes coqenv.sh with the environment needed to run coqc.
#
#   ./setup-coq.sh            # installs into $HOME/.local/coqroot
#   source ./coqenv.sh        # puts coqc on PATH
#
# If you have sudo, `sudo apt install coq` is simpler and this script is
# unnecessary.
set -euo pipefail

PREFIX="${COQ_PREFIX:-$HOME/.local/coqroot}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PKGS=(coq libcoq-stdlib libcoq-core-ocaml libfindlib-ocaml libstdlib-ocaml
      libzarith-ocaml ocaml-base ocaml-findlib libgmp10)

echo "Downloading packages into $WORK ..."
( cd "$WORK" && apt-get download "${PKGS[@]}" )

echo "Unpacking into $PREFIX ..."
mkdir -p "$PREFIX"
for deb in "$WORK"/*.deb; do dpkg-deb -x "$deb" "$PREFIX"; done

cat > "$(dirname "$0")/coqenv.sh" <<EOF
export COQROOT=$PREFIX
export PATH=\$COQROOT/usr/bin:\$PATH
export COQLIB=\$COQROOT/usr/lib/ocaml/coq
export COQCORELIB=\$COQROOT/usr/lib/ocaml/coq-core
export CAML_LD_LIBRARY_PATH=\$COQROOT/usr/lib/ocaml/stublibs:\$COQROOT/usr/lib/x86_64-linux-gnu
export LD_LIBRARY_PATH=\$COQROOT/usr/lib/x86_64-linux-gnu:\${LD_LIBRARY_PATH:-}
EOF

echo "Done.  Run:  source $(dirname "$0")/coqenv.sh && make"
"$PREFIX/usr/bin/coqc" --version || true
