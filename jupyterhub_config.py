# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Modified by Brian Aydemir <baydemir@morgridge.org>.

import os

c = get_config()

# We rely on environment variables to configure JupyterHub so that we
# can avoid having to rebuild the container's image every time we change
# a configuration parameter.

# --------------------------------------------------------------------------

## Configure networking.
c.JupyterHub.port = 443
c.JupyterHub.ssl_key = os.environ["SSL_KEY"]
c.JupyterHub.ssl_cert = os.environ["SSL_CERT"]

c.JupyterHub.hub_ip = "jupyterhub"
c.JupyterHub.hub_port = 8080

## Configure persistent storage.
data_dir = os.environ["HUB_VOLUME_PATH"]
c.JupyterHub.cookie_secret_file = os.path.join(data_dir, "jupyterhub_cookie_secret")

pg_host = os.environ["POSTGRES_HOST"]
pg_password = os.environ["POSTGRES_PASSWORD"]
pg_db = os.environ["POSTGRES_DB"]
c.JupyterHub.db_url = f"postgresql://postgres:{pg_password}@{pg_host}/{pg_db}"

## Authenticate users with GitHub OAuth.
c.JupyterHub.authenticator_class = "oauthenticator.GitHubOAuthenticator"
c.GitHubOAuthenticator.oauth_callback_url = os.environ["OAUTH_CALLBACK_URL"]

# --------------------------------------------------------------------------

## Spawn single-user notebooks as Docker containers.
c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"

## Spawn containers from this image.
c.DockerSpawner.container_image = os.environ["SINGLEUSER_IMAGE"]
spawn_cmd = os.environ["SINGLEUSER_CMD"]
c.DockerSpawner.extra_create_kwargs.update({"command": spawn_cmd})

## Connect containers to this Docker network.
network_name = os.environ["DOCKER_NETWORK_NAME"]
c.DockerSpawner.network_name = network_name
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.extra_host_config = {"network_mode": network_name}

## Set the notebook directory, and mount the user's Docker volume.
notebook_dir = os.environ["SINGLEUSER_VOLUME_PATH"]
c.DockerSpawner.notebook_dir = notebook_dir
c.DockerSpawner.volumes = {"jupyterhub-user-{username}": notebook_dir}

## Remove containers once they are stopped.
c.DockerSpawner.remove_containers = True

## Enable debug logging.
c.DockerSpawner.debug = True
