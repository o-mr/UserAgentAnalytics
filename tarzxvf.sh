#!/bin/sh

find /share/accesslog -name "*.tar.Z" | while read file; do
    path=${file%/*}
    echo ${path}
    cd ${path}
    echo ${file}
    tar zxvf ${file}
done
