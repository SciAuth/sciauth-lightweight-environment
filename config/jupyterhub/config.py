# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Modified by Brian Aydemir <baydemir@morgridge.org>.

import os
import sys

c = get_config()

# --------------------------------------------------------------------------

# This first section contains the configuration that is specific to the
# lightweight environment. The later sections contain standard configuration
# for JupyterHub and DockerSpawner.

# Authenticate users with CILogon.
c.JupyterHub.authenticator_class = "oauthenticator.CILogonOAuthenticator"
c.CILogonOAuthenticator.additional_username_claims = ["email"]
c.CILogonOAuthenticator.oauth_callback_url = os.environ["OAUTH_CALLBACK_URL"]

# Configure the SciTokens service.
scitokens_service_port = os.environ["SCITOKENS_SERVICE_PORT"]
c.JupyterHub.services = [
    {
        "name": "scitokens",
        "url": f"http://jupyterhub:{scitokens_service_port}",
        "command": [sys.executable, "-m", "scitokens.jupyter.token_service"],
        "environment": {"SCITOKENS_SERVICE_PORT": scitokens_service_port},
    },
]

# Prevent the singleuser image that we are using from starting its own local
# HTCondor pool.
c.DockerSpawner.environment = {
    "_condor_SCHEDD_HOST": "htcondor.localdomain",
}

# --------------------------------------------------------------------------

# Configure networking.
c.JupyterHub.port = 443
c.JupyterHub.ssl_cert = os.environ["TLS_CRT"]
c.JupyterHub.ssl_key = os.environ["TLS_KEY"]

c.JupyterHub.hub_ip = "jupyterhub"
c.JupyterHub.hub_port = 8080

# Configure persistent storage.
data_dir = os.environ["HUB_VOLUME_PATH"]
c.JupyterHub.cookie_secret_file = os.path.join(data_dir, "jupyterhub_cookie_secret")

pg_host = os.environ["POSTGRES_HOST"]
pg_password = os.environ["POSTGRES_PASSWORD"]
pg_db = os.environ["POSTGRES_DB"]
c.JupyterHub.db_url = f"postgresql://postgres:{pg_password}@{pg_host}/{pg_db}"

# --------------------------------------------------------------------------

# Spawn single-user notebooks as Docker containers.
c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"

# Spawn containers from this image.
c.DockerSpawner.container_image = os.environ["SINGLEUSER_IMAGE"]
spawn_cmd = os.environ["SINGLEUSER_CMD"]
c.DockerSpawner.extra_create_kwargs.update({"command": spawn_cmd})

# Connect containers to this Docker network.
network_name = os.environ["DOCKER_NETWORK_NAME"]
c.DockerSpawner.network_name = network_name
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.extra_host_config = {"network_mode": network_name}

# Set the notebook directory, and mount the user's Docker volume.
notebook_dir = os.environ["SINGLEUSER_VOLUME_PATH"]
c.DockerSpawner.notebook_dir = notebook_dir
c.DockerSpawner.volumes = {"jupyterhub-user-{username}": notebook_dir}

# Enable debug logging.
c.DockerSpawner.debug = True

# Remove containers once they are stopped.
c.DockerSpawner.remove_containers = True
