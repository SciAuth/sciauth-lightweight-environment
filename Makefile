# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Modified by Brian Aydemir <baydemir@morgridge.org>.

include .env

.PHONY: all build clean clean-docker config docker secrets

all: build

build: config docker secrets
	docker compose build

clean: clean-docker

#---------------------------------------------------------------------------

config:
	mkdir -m u=rwx,go= -p secrets/
	test -e secrets/jupyterhub_svc_config.yaml || cp templates/jupyterhub_svc_config.yaml secrets/
	test -e secrets/user-config.json || cp templates/user-config.json secrets/

#---------------------------------------------------------------------------

docker:

	# Create Docker volumes for persisting data between runs.

	docker volume create $(DB_VOLUME_NAME)
	docker volume create $(HUB_VOLUME_NAME)
	docker volume create $(TOKEN_ISSUER_VOLUME_NAME)

	# Create a Docker network for isolating the containers.

	docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 \
	  || docker network create $(DOCKER_NETWORK_NAME)

clean-docker:

	# Remove the Docker network and volumes created by this Makefile.
	# User data volumes will not be removed, nor will any images created
	# by this Makefile or Docker Compose setup.

	-docker network rm $(DOCKER_NETWORK_NAME)
	-docker volume rm $(DB_VOLUME_NAME) $(HUB_VOLUME_NAME) $(TOKEN_ISSUER_VOLUME_NAME)

#---------------------------------------------------------------------------

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
	# in this Docker Compose setup. It is somewhat simpler to accept
	# or trust one such certificate rather than many.

	openssl req -x509 \
	  -subj "//CN=localhost" \
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
	  --no-cache \
	  --pull \
	  .

	docker run -it --rm $(SCITOKENS_IMAGE) \
	  python3 -m scitokens.tools.admin_create_key \
	    --create-keys \
	    --jwks-private \
	  > secrets/token-issuer.jwks
