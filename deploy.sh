#!/usr/bin/env bash

set -euo pipefail

source .env

for f in \
    namespace.yaml \
    deployment.yaml \
    service.yaml
do
    envsubst < "$f" | kubectl apply -f -
done
