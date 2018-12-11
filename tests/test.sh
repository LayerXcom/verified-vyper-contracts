#!/bin/sh

# This script is assumed to run on Ubuntu 18.04.
ARGS=$1

apt-get update

pip install -r requirements.txt

flake8 ${ARGS}

pytest ${ARGS}
