#!/bin/bash

if [ $# -eq 0 ]; then
    echo "No program provided"
    exit 1
fi

if [ $# -ne 1 ]; then
    echo "Provided too many arguments"
    exit 1
fi

program="$1"

if [ ! -f "$program" ]; then
    echo "File '$program' does not exist"
    exit 1
fi

nasm -f elf64 "$program" -o client.o && ld client.o -o client

