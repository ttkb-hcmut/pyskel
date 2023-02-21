# Pyskel
Python Semantics in Skel.

## Building the project

To build the projetct, you first need to install necro:
``` sh
opam switch create necro 4.14.0
eval $(opam env)
opam repository add necro https://gitlab.inria.fr/skeletons/opam-repository.git#necro
opam install necrolib
```

The project depends on:
```
pyre-ast
js_of_ocaml
js_of_ocaml-ppx
necroml
necrodebug
```


The project is based on dune, do you can run `dune build` to build and `dune test` to run the test suite.

### Module system

Necro lacks a module system, so we've made our own using the C Preprocessor `cpp`.
Make sure you have it installed on your system.

## Debugger 
A Python debugger is under development, see the `debug` branch.
