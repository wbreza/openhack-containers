#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

dbServer="wabrez-openhack-sql.database.windows.net"
dbUser="wabrez"
dbPassword="<password>"
dbName="myDrivingDB"

docker run \
    -e SQLFQDN=$dbServer \
    -e SQLUSER=$dbUser \
    -e SQLPASS=$dbPassword \
    -e SQLDB=$dbName \
    openhack/data-load:v1\
