#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

ipAddr=$1
dbServer=$1
dbUser="sa"
dbName="myDrivingDB"
dbPassword=$2

docker container rm ohsql -f
docker container rm poi-api -f
docker container rm userprofile-api -f
docker container rm trips-api -f
docker container rm tripviewer-ui -f

# Create SQL Container
docker run \
    -e ACCEPT_EULA=Y \
    -e SA_PASSWORD=$dbPassword \
    -p 1433:1433 \
    --name ohsql -d \
    mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
    
sleep 20 # Wait a little bit for the SQL server to initialize

# Create the database
sqlcmd -S $dbServer,1433 -U SA -P "$dbPassword" -i ./setup.sql

# Data load
docker run \
    -e SQLFQDN=$dbServer \
    -e SQLUSER=$dbUser \
    -e SQLPASS=$dbPassword \
    -e SQLDB=$dbName \
    openhack/data-load:v1\

# Create APIs
docker run -d -p 8081:80 \
    --name poi-api \
    -e SQL_USER=$dbUser \
    -e SQL_PASSWORD=$dbPassword \
    -e SQL_SERVER=$dbServer \
    -e SQL_DBNAME=$dbName \
    wabrezohcontainerregistry.azurecr.io/poi 

docker run -d -p 8082:80 \
    --name userprofile-api \
    -e SQL_USER=$dbUser \
    -e SQL_PASSWORD=$dbPassword \
    -e SQL_SERVER=$dbServer \
    -e SQL_DBNAME=$dbName \
    wabrezohcontainerregistry.azurecr.io/userprofile

docker run -d -p 8083:80 \
    --name trips-api \
    -e SQL_USER=$dbUser \
    -e SQL_PASSWORD=$dbPassword \
    -e SQL_SERVER=$dbServer \
    -e SQL_DBNAME=$dbName \
    wabrezohcontainerregistry.azurecr.io/trips

# Create UIs
docker run -d -p 8080:80 \
    --name tripviewer-ui \
    -e SQL_USER=$dbUser \
    -e SQL_PASSWORD=$dbPassword \
    -e SQL_SERVER=$dbServer \
    -e SQL_DBNAME=$dbName \
    -e TRIPS_API_ENDPOINT="http://$ipAddr:8083" \
    -e USER_API_ENDPOINT="http://$ipAddr:8082" \
    -e BING_MAPS_KEY="AiVZurOu5-zAjFCsq4_hzsHilRAnQ2rMyLhfJKSTqN4tweyhs53iguG7MtgwZ1kg" \
    wabrezohcontainerregistry.azurecr.io/tripviewer

docker container ps
