#!/bin/sh

# This script is assumed to run on Ubuntu 18.04.
ARGS=$1

apt-get update
apt-get install -y build-essential m4 openjdk-8-jdk libgmp-dev libmpfr-dev pkg-config flex z3 libz3-dev maven opam python3 pandoc

# use java8
update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

# remove existing build?
rm -rf .build/k && rm -rf .build/evm-semantics

make all

# make specs
make ${ARGS}

# run test
make test
