---
title: "How to check that an SSL certificate and its private key match"
date: "2026-03-09"
description: "A one liner to keep around"
tags:
  - "Bash"
  - "Linux"
  - "Toolbox"
---

## Introduction

Though it is less common nowadays, SSL certificate provisioning can still be
full of surprises when dealing with old school setups in client environments.

Some colleagues did not know how to easily check if a certificate and private
key match in a clean one liner, and their LLM research came up with
"interesting" suggestions with at least 6 pipes and too many checksum
operations.

This prompted me to document my way of doing this.

## Extracting the public key

The public key can be extracted with openssl using two commands. Here is the
first one for the certificate:

``` shell
openssl x509 -in mycertificate.crt -noout -pubkey
```

Here is the second one for the private key:

``` shell
openssl pkey -in mykey.key -pubout
```

## The diff command and process substitutions

Bash process substitutions are very useful, in particular in this context. They
allow a command to read the output of other commands as pseudo files. For our
purpose it looks like this:

``` shell
diff  -quw <(openssl x509 -in mycertificate.crt -noout -pubkey) \
           <(openssl pkey -in mykey.key  -pubout)
```

The `-quw` flags are not important here, just a habit of mine. `-q` is to ask
diff to be quiet, `-u` is to ask for a unified output while `-w` is to ignore
whitespace differences.

If running the diff command from a script, know that it also exits `0` when the
inputs are the same, 1 if they are different and >1 if another error occurred.

## Conclusion

This provides a quick way to verify that a certificate and its private key
match, while also demonstrating Bash process substitution. I encourage anyone to
use these process substitutions more, they have many practical uses and can
simplify command line workflows.
