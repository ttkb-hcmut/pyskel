# Pyskel
Python Semantics in Skel.

## Building the project

First, ensure to have `opam` and `dune` installed on your system.
To build the projetct, you first need to install the necro toolchain.
``` sh
opam switch create pyskel 4.14.1
eval $(opam env)
opam repository add necro https://gitlab.inria.fr/skeletons/opam-repository.git#necro
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
dune test # to run the test suite, or
dune exec pyskel path_to_file.py # to run a given file
```

Note that since `pyskel` has no printing support at the moment, the contents of the `__result__` global variable are displayed after the execution of the python file. Please set it in your code to observe its execution.

### Module system

Necro lacks a module system, so we've made our own using the C Preprocessor `cpp`.
Make sure you have it installed on your system.

## Debugger 
A Python debugger is under development, see the `debug` branch.
