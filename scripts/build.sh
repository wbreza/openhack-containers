#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

az.cmd acr login --name wabrezohcontainerregistry

docker build -t poi ../src/poi
docker tag poi wabrezohcontainerregistry.azurecr.io/poi
docker push wabrezohcontainerregistry.azurecr.io/poi

docker build -t userprofile ../src/userprofile
docker tag userprofile wabrezohcontainerregistry.azurecr.io/userprofile
docker push wabrezohcontainerregistry.azurecr.io/userprofile

docker build -t trips ../src/trips
docker tag trips wabrezohcontainerregistry.azurecr.io/trips
docker push wabrezohcontainerregistry.azurecr.io/trips

docker build -t tripviewer ../src/tripviewer
docker tag tripviewer wabrezohcontainerregistry.azurecr.io/tripviewer
docker push wabrezohcontainerregistry.azurecr.io/tripviewer