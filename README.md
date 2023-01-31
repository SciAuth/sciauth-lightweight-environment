# SciAuth Lightweight Environment

This repository provides an end-to-end software environment that facilitates the experimentation with [SciTokens](https://scitokens.org/) for capability-based authorization in scientific computing. It is a product of the [SciAuth](https://sciauth.org/) project, which encourages the adoption of the SciTokens model through community engagement, support for coordinated adoption of community standards, assistance with software integration, security analysis and threat modeling, training, and workforce development.

The end-to-end software environment consists of a set interconnected
containers orchestrated with [Docker Compose](https://docs.docker.com/compose/).

## Requirements

- A host on which you may run [Docker Compose](https://docs.docker.com/compose/). The host need not be publicly accessible.
- Any device with an AMD64 architecture (as opposed to ARM64, which has been shown to cause various bugs) for the best experience.

## Quickstart

### Before you start

- By default, services are made available on `localhost` using self-signed certificates. You might need to click through warnings in your web browser regarding the certificates.
- In the case that a browser does not allow such bypass of warnings, try switching browsers, such as from Google Chrome to Safari on a MacOS device.

### Step-by-step guide

1. Create a clone of this repository using the following commands:

```
$ git clone https://github.com/SciAuth/sciauth-lightweight-environment.git
$ cd sciauth-lightweight-environment
```

2. Create a folder called `secrets`. Copy the `oauth.env` file from the `templates` folder into the `secrets` folder. Run `make secrets`.

3. Run `make build` to build the preliminary elements of the repository. Be sure to use Git Bash, which comes with [Git for Windows](https://git-scm.com/downloads) to run this command.

4. Run `docker compose up -d` to build the Docker containers with [Docker Compose](https://docs.docker.com/compose/).

5. Experiment with the various workflows or the API endpoints. See the sections below for a detailed guide.

6. To stop the [Docker Compose](https://docs.docker.com/compose/) containers, run `docker compose down`.

## Experimenting with API endpoints

The lightweight environment is integrated with a demo app with various public and private API endpoints that can be experimented with after requiring some manual but minimal configurations on the user's end. The detailed steps are as follows:

1. Visit https://cilogon.org and login with an identity provider of your preference.
2. After successful login, you will be greeted with a table of user-specific information in the TODO section. Copy the URL in the first (which exactly? TODO) row and create a record with the following format in the `user-config.json` file in the `secrets` folder.

```
  "<YOUR URL>": {
    "eduPersonEntitlement": [""],
    "audience": "https://token-issuer.localdomain"
  },
```

3. Now, replace the empty string associated with `eduPersonEntitlement` with one or multiple space-separated scopes string. These scopes will dictate which actions your token authorizes you to perform on a set of test API endpoints. A scope's format and various options are as follows:
   - Format: `<ACTION>:/<ENDPOINT>/<USER (optional)>`
   - Options:
     - `<ACTION>`: `read`, `write`, `update`, `delete`
     - `<ENDPOINT>`: `properties`
     - `<USER>`: `linh`, `yolanda`
   - An example of a valid token would be: `"read:/properties write:/properties update:/properties delete:/properties/linh"`
4. At this point, you have created a configuration file which dictates which tokens should be returned to you by the lightweight environment's token issuer, given that you use the chosen identity provider. An example of a valid `user-config.json` file would be as provided below. Be mindful of the use of commas to separate contiguous records.

```
{
  ...
    "audience": "my_rabbit_server"
  },
  "http://cilogon.org/serverE/users/123456": {
    "eduPersonEntitlement": ["read:/properties write:/properties update:/properties delete:/properties/linh"],
    "audience": "https://token-issuer.localdomain"
  },
  "default_claim": {
    ...
}
```

5. Run the following commands in succession:

```
$ docker compose down
$ make build
$ docker compose up -d
```

8. Visit https://localhost/services/scitokens/. The following sequence of actions must be done in the exact order specified to ensure the intended behavior:
   - Select `1. Authorize` to authorize a built-in token management service to fetch a token on your behalf.
   - Copy the 10-digit dash-separated code to your clipboard.
   - Follow the instructions on the page to finish the log on process.
   - Return to the token management service page by clicking on the URL. TODO
   - Select `2. Fetch token` to get your token. Copy it to your clipboard for later use.
9. Now, you can start experimenting with the endpoints themselves using `curl` requests or other API testing softwares. You should be able to perform actions according to the scopes specified in the previous steps.

### Example interactions with API endpoints

If your configuration looks exactly like the one in step 4, you should be able to run the following commands and get the exact same responses as below. Note that since we're using a self-signed certificate, the `--insecure` flag needs to be passed to `curl`. This does not pose any threat to your device.

#### GET (Read)

```bash
$ curl --insecure --request GET \
  --url https://localhost:3001/properties/linh \
  --header 'authorization: Bearer <YOUR_TOKEN>'
```

**Response**

```
[{"amount":5000,"description":"truck"},{"amount":70000,"description":"condo"}]
```

#### POST (Write)

```bash
$ curl --insecure --request POST \
  --url https://localhost:3001/properties/linh \
  --header "Content-Type: application/json" --data '{
    "amount": 10000,
    "description": "land"
}' \
  --header 'authorization: Bearer <your_sample_token>'
```

**Response**

There is no terminal output for this command. Internally, you have written a new record `{
    "amount": 10000,
    "description": "land"
}` at the `properties/linh` endpoint. If you call `GET` again, you should expect:

```
[{"amount":5000,"description":"truck"},{"amount":70000,"description":"condo"},{"amount":10000,"description":"land"}]
```

#### PUT (Update)

```bash
$ curl --insecure --request PUT \
  --url https://localhost:3001/properties/linh \
  --header "Content-Type: application/json" --data'[{"amount": 10000,
    "description": "land"}, {"amount": 8000, "description": "house"}]' \
  --header 'authorization: Bearer <YOUR_TOKEN>'
```

**Response**

There is no terminal output for this command. Internally, you have updated the record `{"amount": 10000,
    "description": "land"}` to be `{"amount": 8000, "description": "house"}` at the `properties/linh` endpoint. If you call `GET` again, you should expect:

```
[{"amount":5000,"description":"truck"},{"amount":70000,"description":"condo"},{"amount":8000,"description":"house"}]
```

#### DELETE (Delete)

```bash
$ curl --insecure --request DELETE \
  --url https://localhost:3001/properties/linh \
  --header "Content-Type: application/json" --data '{
    "amount": 8000,
    "description": "house"
}' \
  --header 'authorization: Bearer <YOUR_TOKEN>'
```

**Response**

There is no terminal output for this command. Internally, you have deleted the record `{
    "amount": 8000,
    "description": "house"
}` at the `properties/linh` endpoint. If you call `GET` again, you should expect:

```
[{"amount":5000,"description":"truck"},{"amount":70000,"description":"condo"}]
```

### Validating token scopes

Since the token allows delete permissions on `/properties/linh` but not `/properties/yolanda`, you will see a `Validation incorrect` error if you try to DELETE `/properties/yolanda`. For example:

```bash
$ curl --insecure --request DELETE \
  --url http://127.0.0.1:5000/properties/yolanda \
  --header "Content-Type: application/json" --data '{
    "amount": 100000,
    "description": "house"
}' \
  --header 'authorization: Bearer <YOUR_TOKEN>'
```

should give the following response:

```
Validation incorrect: Validator rejected value of 'read:/properties write:/properties update:/properties delete:/properties/linh' for claim 'scope'
```

You can modify the scopes in the fetched token to test different authorizations by repeating steps 3 through 8 of this section.

### Testing Expiration

If your token is too old, you will see the following error when trying to perform any action on any of the endpoints:

```
Unable to deserialize: %Signature has expired
```

By default, the tokens are valid for 15 minutes. In the case that a token expires, you can get a new token simply by repeating step 8 of this section.

## Experimenting with workflows

Work in Progress
