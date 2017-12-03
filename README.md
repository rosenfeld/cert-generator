# Docker image to generate self-signed root CA and sample certificate from a web server

    docker run --rm -p 4000:80 rosenfeld/cert-generator

Then simply point your browser to http://localhost:4000 to generate your dev certificates.

Unzip the returned value and read INSTRUCTIONS.html for further information on installing them.

Automatically built from Github, but you can build with:

    docker build --tag rosenfeld/cert-generator .

The container is available in Docker Hub [here](https://hub.docker.com/r/rosenfeld/cert-generator/).

# Contributions

The source code is available in Github [here](https://github.com/rosenfeld/cert-generator).

The included INSTRUCTIONS.html currently only mentions Linux and nginx. Pull requests to include
instructions for other servers and operating systems are welcomed.
