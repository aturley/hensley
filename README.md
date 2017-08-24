# Hensley

Hensley is a Pony<->Python bridge. It is named after George Went
Hensley, who popularized the religious practice of snake handling and
died of a snake bite on July 25, 1955.

## Building

```
clang -g -o build/hensley.o -c src/hensley.c \
  && ar rvs build/libhensley.a build/hensley.o
ponyc --path=build .
```

## Running

Currently the main application opens the file `ponytest.py`, calls
some of methods in the file, and prints the results.

```
PYTHONPATH=.
./hensley
```
