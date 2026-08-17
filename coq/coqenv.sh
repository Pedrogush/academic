export COQROOT=$HOME/.local/coqroot
export PATH=$COQROOT/usr/bin:$PATH
export COQLIB=$COQROOT/usr/lib/ocaml/coq
export COQCORELIB=$COQROOT/usr/lib/ocaml/coq-core
export CAML_LD_LIBRARY_PATH=$COQROOT/usr/lib/ocaml/stublibs:$COQROOT/usr/lib/x86_64-linux-gnu
export LD_LIBRARY_PATH=$COQROOT/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
