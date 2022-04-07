# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Modified by Brian Aydemir <baydemir@morgridge.org>.

include .env

.PHONY: all build clean clean-docker docker docker-images docker-network docker-volumes secrets secrets-oauth secrets-postgres secrets-ssl secrets-token-issuer

all: build

build: docker secrets
	docker compose build

clean: clean-docker

#---------------------------------------------------------------------------

docker: docker-images docker-network docker-volumes

docker-images:
	docker build -f Dockerfile.singleuser \
	  -t $(SINGLEUSER_IMAGE) \
	  --build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
	  --build-arg SINGLEUSER_BASE_IMAGE=$(SINGLEUSER_BASE_IMAGE) \
	  .

docker-network:
	docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(DOCKER_NETWORK_NAME)

docker-volumes:
	docker volume inspect $(HUB_VOLUME_NAME) >/dev/null 2>&1 || docker volume create --name $(HUB_VOLUME_NAME)
	docker volume inspect $(DB_VOLUME_NAME) >/dev/null 2>&1 || docker volume create --name $(DB_VOLUME_NAME)
	docker volume inspect $(TOKEN_ISSUER_VOLUME_NAME) >/dev/null 2>&1 || docker volume create --name $(TOKEN_ISSUER_VOLUME_NAME)

clean-docker:
	-docker network rm $(DOCKER_NETWORK_NAME)
	-docker volume rm $(HUB_VOLUME_NAME) $(DB_VOLUME_NAME) $(TOKEN_ISSUER_VOLUME_NAME)

#---------------------------------------------------------------------------

secrets: secrets-oauth secrets-postgres secrets-ssl secrets-token-issuer

secrets-oauth: secrets/oauth.env

secrets/oauth.env:
	mkdir -m u=rwx,go= -p secrets/
	@echo ""
	@echo "ERROR: No such file: $@"
	@echo ""
	@echo "Create this file, and add the following three lines:"
	@echo ""
	@echo "GITHUB_CLIENT_ID=<GitHub OAuth2 Client ID>"
	@echo "GITHUB_CLIENT_SECRET=<GitHub OAuth2 Client Secret>"
	@echo "OAUTH_CALLBACK_URL=https://localhost/hub/oauth_callback"
	@echo ""
	@exit 1

secrets-postgres: secrets/postgres.env

secrets/postgres.env:
	mkdir -m u=rwx,go= -p secrets/
	@echo "Generating postgres password in $@."
	@echo "POSTGRES_PASSWORD=$(shell openssl rand -hex 32)" > $@

secrets-ssl: secrets/hub.crt secrets/hub.key secrets/token-issuer.crt secrets/token-issuer.key

secrets/hub.crt secrets/hub.key:
	mkdir -m u=rwx,go= -p secrets/
	@echo "Generating SSL certificate for localhost in secrets/hub.crt."
	openssl req -x509 -subj "/CN=localhost" -newkey rsa:4096 -out secrets/hub.crt -keyout secrets/hub.key -sha256 -days 365 -nodes

secrets/token-issuer.crt secrets/token-issuer.key:
	mkdir -m u=rwx,go= -p secrets/
	@echo "Generating SSL certificate for the token issuer in secrets/token-issuer.crt."

	printf '[req]\n' > secrets/token-issuer.req
	printf 'distinguished_name=req\n' >> secrets/token-issuer.req
	printf '[san]\n' >> secrets/token-issuer.req
	printf 'subjectAltName=DNS:localhost,DNS:token-issuer\n' >> secrets/token-issuer.req

	openssl req -x509 -subj "/CN=localhost" -newkey rsa:4096 -out secrets/token-issuer.crt -keyout secrets/token-issuer.key -sha256 -days 365 -nodes -extensions san -config secrets/token-issuer.req

secrets-token-issuer: secrets/token-issuer.jwks

secrets/token-issuer.jwks:
	mkdir -m u=rwx,go= -p secrets/
	docker build -f Dockerfile.scitokens -t scitokens .
	docker run -it --rm scitokens python3 -m scitokens.tools.admin_create_key --create-keys --pem-private > secrets/token-issuer.pem
	docker run -it --rm -v $(shell pwd)/secrets:/secrets scitokens python3 -m scitokens.tools.admin_create_key --private-key /secrets/token-issuer.pem --jwks-private > secrets/token-issuer.jwks
