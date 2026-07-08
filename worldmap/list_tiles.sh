#!/bin/sh

for path in $(find $1 -type f); do
    echo $(basename $(dirname $path))/$(basename $path)
done
