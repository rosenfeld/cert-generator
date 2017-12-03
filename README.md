# Docker image to generate self-signed root CA and sample certificate from a web server

    docker run --rm -p 4000:80 rosenfeld/cert-generator

Then simply point your browser to http://localhost:4000 to generate your dev certificates.

Unzip the returned value and read INSTRUCTIONS.html for further information on installing them.

Built with:

    docker build --tag rosenfeld/cert-generator .

# Contributions

The included INSTRUCTIONS.html currently only mentions Linux and nginx. Pull requests to include
instructions for other servers and operating systems are welcomed.
