#!/bin/bash

noext() {
    echo $1 | perl -pe 's/\.\w+$//g'
}

p6pir() {
    src=`noext $1`
    echo "Compiling $1 to $src.pir"
    perl6 --target=pir --output=$src.pir $1
}

pir2pbc() {
    src=`noext $1`
    echo "Compiling $1 to $src.pbc"
    parrot -o $src.pbc $1
}

pushd lib
for file in `find . -name '*.pm'`; do
    p6pir $file
done
popd

