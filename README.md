A docker compose file and some auxillary scripts for running a [Polymesh Private](https://polymesh.network/) development environment via `docker compose`

## Prerequisites

Docker 19.03.0+ for you platform installed and running. Download and setup instructions can be found here: <https://docs.docker.com/get-docker/>

The docker daemon needs to be running before compose will work. (Try `docker ps` to see if the daemon responds)

## Running

Use `docker compose up -d` to bring up the services. `docker compose down` will stop them.

The default .env file is present as a symlink. If you want to use different versions, overwrite it or link to any other existing env files in the ./envs directory. Alternatively a file patch can be given explicitly to docker compose, e.g. `docker compose --env-file=envs/1.0 up`.

This will bring up:

- Single node Polymesh Private chain in a dev mode
- Polymesh REST API
- Polymesh Proof API
- Hashicorp Vault as a signing manager for the Polymesh Rest API
- Subquery indexer
- Subquery graphql server
- Postgres (subquery dependency)

This set of services should allow for testing most integrations.

Bear in mind, it will take a couple of minutes during the first run to setup everything. In general, once the polymesh-rest-api-init container exits (it will print a message that the setup is completed), you should be good to go.

Following signers with keys stored in Vault are created that can be used to sign transactions. They have proper CDD claim and some POLYX.

- sender-1
- receiver-1
- mediator-1

## Statefullnes

The docker compose file uses named volumes to persist state where applicable. This is true for:

- Polymesh Private node
- Hashicorp Vault
- Postgresql

Thanks to that, the whole environment will store its state during restarts.

```sh
$ docker volume ls
DRIVER    VOLUME NAME
local     polymesh-private_pp-chain-data
local     polymesh-private_pp-psql-data
local     polymesh-private_pp-rest-api-signer-init
local     polymesh-private_pp-vault-log-volume
local     polymesh-private_pp-vault-root-token
local     polymesh-private_pp-vault-volume
```

In case you want to start from scratch, you need to stop the containers and remove these volumes.

```sh
docker compose down --volumes
```

## Additional Notes

To access Vault UI at http://localhost:8200 you need the root token. You can get it with this command:

```sh
docker compose logs vault-init 
```

It should be printed in the last line.

## List of web interfaces exposed to localhost with their default ports:

- http://localhost:3000 <-- Subquery GraphQL
- http://localhost:3001 <-- Polymesh Rest API
- http://localhost:8080/swagger-ui/ <-- Polymesh Proof API
- http://localhost:8020 <-- Hashicorp Vault, signing manager

## List of remaining services exposed to localhost with their default ports:

- localhost:9944 <-- polymesh-private WebSocket endpoint
- localhost:9933 <-- polymesh-private HTTP endpoint
- localhost:30333 <-- polymesh-private p2p endpoint
