# Pyskel
Python Semantics in Skel.

## Building the project

First, ensure to have `opam` and `dune` installed on your system.
To build the projetct, you first need to install the necro toolchain.
(Note that version 0.3 and above of `necroml` is not yet supported, hence the `pin` instruction below.)
``` sh
opam switch create pyskel 4.14.0
eval $(opam env)
opam repository add necro https://gitlab.inria.fr/skeletons/opam-repository.git#necro
opam pin necroml 0.2.11.4.1
opam install necroml pyre-ast
```

And, optionally, for the debug branch (experimental):
```
opam install necrodebug js_of_ocaml js_of_ocaml-ppx
```

To build the project, go in `Semantics/pyskel` and run:
``` sh
./setup.sh
dune build
dune test # to run the test suite
```

### Module system

Necro lacks a module system, so we've made our own using the C Preprocessor `cpp`.
Make sure you have it installed on your system.

## Debugger 
A Python debugger is under development, see the `debug` branch.
