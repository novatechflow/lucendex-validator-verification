#!/bin/bash
# Wrapper to run validator-keys via Docker
# Usage: validator-keys-wrapper.sh [validator-keys arguments]

# If first arg is create_keys, add --keyfile to specify location
if [ "$1" = "create_keys" ]; then
    docker run --rm \
        --platform linux/amd64 \
        -v "${HOME}/.validator-keys-secure:/keys" \
        -w /keys \
        validator-keys-builder:latest \
        create_keys --keyfile validator-keys.json
else
    docker run --rm \
        --platform linux/amd64 \
        -v "${HOME}/.validator-keys-secure:/keys" \
        -w /keys \
        validator-keys-builder:latest \
        "$@"
fi
