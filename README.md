A docker compose file and some auxillary scripts for running a [Polymesh Private](https://polymesh.network/) development environment via `docker compose`

## Prerequisites

Docker 19.03.0+ for you platform installed and running. Download and setup instructions can be found here: <https://docs.docker.com/get-docker/>

The docker daemon needs to be running before compose will work. (Try `docker ps` to see if the daemon responds)

## Running

Copy the correct env over to a `.env` from `envs/` e.g. `cp envs/1.0 .env`. This file specifies the images that will be used. Alternatively a file patch can be given explicitly to docker compose, e.g. `docker compose --env-file=envs/1.0 up`

Once an `.env` file is present use `docker compose up -d` to bring up the services. `docker compose down` will stop them.

This will bring up:

- Single node Polymesh Private chain in a dev mode
- Polymesh REST API
- Polymesh Proof API
- Hashicorp Vault as a signing manager for the Polymesh Rest API
- Subquery indexer
- Subquery graphql server
- Postgres (subquery dependency)

This set of services should allow for testing most integrations

## Statefullnes

The docker compose file uses named volumes to persist state where applicable. This is true for:

- Polymesh Private node
- Hashicorp Vault
- Postgresql

Thanks to that, the whole environment will store its state during restarts.

```sh
$ docker volume ls
DRIVER    VOLUME NAME
local     docker_pp-chain-data
local     docker_pp-psql-data
local     docker_pp-vault-init-volume
local     docker_pp-vault-log-volume
local     docker_pp-vault-root-token
local     docker_pp-vault-volume
```

In case you want to start from scratch, you need to stop the containers and remove these volumes.

```sh
docker compose down
docker volume ls --filter label=network.polymesh.project=polymesh-private --quiet | xargs --max-args=1 --no-run-if-empty docker volume rm --force
```

## Additional Notes