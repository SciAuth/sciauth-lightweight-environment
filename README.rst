SciAuth Lightweight Environment
===============================

This repository provides an end-to-end software environment that enables
experimentation with using SciTokens_ for capability-based authorization in
scientific computing. It is a product of the SciAuth_ project, which
supports the adoption of the SciTokens model through community engagement,
support for coordinated adoption of community standards, assistance with
software integration, security analysis and threat modeling, training, and
workforce development.

The end-to-end software environment consists of a set interconnected
containers orchestrated with `Docker Compose`_.

.. _Docker Compose: https://docs.docker.com/compose/
.. _SciAuth: https://sciauth.org/
.. _SciTokens: https://scitokens.org/


Requirements
------------

A host on which you may run `Docker Compose`_. The host need not be publicly
accessible.


Quickstart
----------

NOTE: By default, services are made available on ``localhost`` using
self-signed certificates. You might need to click through warnings in your
web browser regarding the certificates.

1. Create a clone of this repository.

2. Run ``make build``.

3. Run ``docker compose up -d``.

4. Visit https://localhost:8443/scitokens-server/register and register a new
   OAuth client with the following configuration:

   ==============================  ============================================
   Client Name                     Any name
   Contact Email                   Any valid-looking email address
   Home URL                        https://localhost/
   Callback URLs                   https://localhost/services/sciauth/tokens/lightweight-issuer/auth
   Scopes                          Select exactly ``openid`` and ``profile``
   Refresh Token Lifetime          Any number of seconds
   Issuer                          Leave blank
   Use limited proxy certificates  Leave unselected
   Is this client public           Leave unselected
   ==============================  ============================================

   Make a note of the client identifier and client secret.

5. Edit ``secrets/jupyterhub_svc_config.yaml``. In the section for
   "Lightweight Token Issuer", replace the ``client_id`` and
   ``client_secret`` values with the ones from the previous step.

5. Run ``docker compose restart``.

6. Visit https://localhost/ and experiment with `various workflows`_.

7. Run ``docker compose down``.

.. _various workflows: docs/Workflows.rst


History
-------

This Docker Compose setup is a derivative of jupyterhub-deploy-docker_.

Notable changes include:

- Updating JupyterHub to 1.3.0

.. _jupyterhub-deploy-docker: https://github.com/jupyterhub/jupyterhub-deploy-docker
