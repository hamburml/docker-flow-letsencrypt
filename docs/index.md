# Docker Flow: Let's Encrypt

This companion service creates and renews Let's Encrypt Certificates and reconfigures [Docker Flow: Proxy](https://github.com/vfarcic/docker-flow-proxy) and [Docker Flow: Swarm Listener](https://github.com/vfarcic/docker-flow-swarm-listener) so that all services which should be accessible via Docker Flow Proxy are available via HTTPS (SSL/TLS).

## About Let's Encrypt

[Let's Encrypt](https://letsencrypt.org/) is a free, automated, and open certificate authority (CA), run for the public’s benefit. It is a service provided by the Internet Security Research Group (ISRG). It is free, automatic, secure, transparent, open and cooperative.
With Let's Encrypt we can create certificates, which were then signed by them. All Operating Systems and Browsers who trust Let's Encrypt automatically accept certificates signed by them. 

In short: 

<img style='border:0px;height:228px;' src='chrome_https.png' border='1' />

## Overview

SSL certificates are issued by CAs, organizations that verify the identity and legitimacy of any entity requesting a certificate. In addition a browser trusts all certificates, which were signed by a trusted CA. When you need a SSL certificate for one of your domains you must follow the rules the chosen CA specifies. When using Let's Encrypt as CA you benefit from a workflow which is automatable. 

It is very important that a CA can be sure that you have a access to the domain and the server(s) to which the domain is pointing to. Therefore Let's Encrypt tries to reach your-domain/.well-known/acme-challenge [ACME Specification](https://github.com/ietf-wg-acme/acme/). Certbot is part of EFF's effort to encrypt the entire web and is used by Docker Flow: Let's Encrypt. It supports the ACME protocol and therefore allows the correct creation of certificates signed by Let's Encrypt.

## Usage

Check the [example](example.md) and get started using Docker Flow: Let's Encrypt. Just remeber that the certificates are plain and simple files and therefore need to be stored in a way so that your environment can read them.
