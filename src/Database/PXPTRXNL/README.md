# PXP Transactional Database (PXPTRXNL)

This project is based on the Microsoft Docker Lab for SQL Server: https://github.com/docker/labs/tree/master/windows/sql-server

## Dockerfile.builder
This file builds dependencies of .Net Framework and Microsoft Data Tools for the main Dockerfile:
```Dockerfile.builder
docker image build --tag pxp-database/pxptrxnl-builder --file Dockerfile.builder .
``` 

## Dockerfile

This file builds a DACPAC docker container:
```Dockerfile
docker image build --tag pxp-database/pxptrxnl:v1 --file Dockerfile .
```

Default container with SQLExpress

```RunDefaultDockerfile
docker container run --detach --name pxp-database-pxptrxnl --publish 1433:1433 pxp-database/pxptrxnl:v1
```

Override environment password variable and other variables in DockerEnvs.txt 

To run the container:
```RunDockerfile
docker container run -e sa_password={password} --env-file DockerEnvs.txt  --detach --name pxp-database-pxptrxnl pxp-database/pxptrxnl:v1
```

To see the run log:
```Logockerfile
docker container logs -f pxp-database-pxptrxnl
```

To get the IP of SQLExpress DB:
```RunDockerfile
docker container inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' pxp-database-pxptrxnl
```

To remove the container:
```RemoveDockerfile
docker container rm --force pxp-database-pxptrxnl
```

