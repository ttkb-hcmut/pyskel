# Pyskel
Python Semantics in Skel.

## Building the project

First, ensure to have `opam` and `dune` installed on your system.
To build the projetct, you first need to install the necro toolchain.
``` sh
opam switch create pyskel 4.14.0
eval $(opam env)
opam repository add necro https://gitlab.inria.fr/skeletons/opam-repository.git#necro
opam install necrolib
```

The project depends on:
```
pyre-ast
necroml

```

And, optionally, for the debug branch (experimental):
```
necrodebug
js_of_ocaml
js_of_ocaml-ppx
```

To build the project, go in `Semantics/pyskel` and run `dune build`. You may then run tests using `dune test`.

### Module system

Necro lacks a module system, so we've made our own using the C Preprocessor `cpp`.
Make sure you have it installed on your system.

## Debugger 
A Python debugger is under development, see the `debug` branch.
