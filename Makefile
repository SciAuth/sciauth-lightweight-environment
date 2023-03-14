# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Modified by Brian Aydemir <baydemir@morgridge.org>.

include .env

.PHONY: all build clean config docker secrets

all: build

build: config docker secrets

	# Build services and the images that they depend on.

	docker compose build --pull

clean:

	# Remove Docker networks and volumes created by this Makefile.
	# Retain user data volumes.
	# Retain user configuration and secrets.

	-docker image rm $(HTCONDOR_IMAGE) $(JUPYTERHUB_IMAGE) $(SCITOKENS_IMAGE) $(SINGLEUSER_IMAGE)
	-docker network rm $(DOCKER_NETWORK_NAME)
	-docker volume rm $(DB_VOLUME_NAME) $(HUB_VOLUME_NAME) $(TOKEN_ISSUER_VOLUME_NAME)

#---------------------------------------------------------------------------

config: secrets
	make \
	  secrets/jupyterhub_svc_config.yaml \
	  secrets/user-config.json

secrets/jupyterhub_svc_config.yaml:
	cp templates/jupyterhub_svc_config.yaml secrets/

secrets/user-config.json:
	cp templates/user-config.json secrets/

docker: secrets

	# Create Docker volumes for persisting data between runs.

	docker volume create $(DB_VOLUME_NAME)
	docker volume create $(HUB_VOLUME_NAME)
	docker volume create $(TOKEN_ISSUER_VOLUME_NAME)

	# Create a Docker network for isolating the containers.

	docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 \
	  || docker network create $(DOCKER_NETWORK_NAME)

	# Build images that are not in the Docker Compose setup.

	docker build -f Dockerfile.singleuser -t $(SINGLEUSER_IMAGE) \
	  --pull \
	  --build-arg SINGLEUSER_BASE_IMAGE=$(SINGLEUSER_BASE_IMAGE) \
	  .

secrets:
	mkdir -p secrets/
	chmod u=rwx,go= secrets/
	make \
	  secrets/oauth.env \
	  secrets/postgres.env \
	  secrets/tls.crt \
	  secrets/token-issuer.jwks

secrets/oauth.env:
	@echo
	@echo ERROR: No such file: $@
	@echo
	@echo Create this file based on templates/oauth.env.
	@echo
	@exit 1

secrets/postgres.env:

	# Create a password for the Postgres database's `postgres` user.

	@echo "POSTGRES_PASSWORD=$(shell openssl rand -hex 32)" > $@

secrets/tls.crt:

	# Create a single self-signed certificate for all of the hosts
	# in the Docker Compose setup. It is somewhat simpler to accept
	# or trust one such certificate rather than many.

	openssl req -x509 \
	  -subj "/CN=localhost" \
	  -newkey rsa:4096 \
	  -out secrets/tls.crt \
	  -keyout secrets/tls.key \
	  -days 365 \
	  -nodes \
	  -sha256 \
	  -extensions san \
	  -config config/certificates/tls.req

secrets/token-issuer.jwks:

	# Use the SciTokens library to generate the signing key for the
	# lightweight token issuer.

	docker build -f Dockerfile.scitokens -t $(SCITOKENS_IMAGE) \
	  --pull \
	  .

	docker run --rm $(SCITOKENS_IMAGE) \
	  python3 -m scitokens.tools.admin_create_key \
	    --create-keys \
	    --jwks-private \
	  > secrets/token-issuer.jwks
