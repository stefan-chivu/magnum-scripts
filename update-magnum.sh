#!/bin/bash -e

echo "Getting latest magnum changes from fork..."

cd /opt/stack/magnum

git pull --rebase origin management-cluster-driver -f
