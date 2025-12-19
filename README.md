# docker-p4d

[![Build](https://github.com/frozenfoxx/docker-p4d/actions/workflows/build.yml/badge.svg)](https://github.com/frozenfoxx/docker-p4d/actions/workflows/build.yml)

A [Docker](https://docker.io) container for running a [Perforce P4](https://help.perforce.com/helix-core/quickstart/current/Content/quickstart/Home-quickstart.html) server.

Docker Hub: https://hub.docker.com/r/frozenfoxx/p4d

# How to Build

To build the default image input the following:

```Shell
git clone https://github.com/frozenfoxx/docker-p4d.git
cd docker-p4d
docker build -t frozenfoxx/p4d:latest .
```

# How to Use this Image

## Quickstart

The following will run the latest P4 server with a default configuration:

```Shell
docker run -it \
  --rm \
  -p 1666:1666 \
  -v /server/mount/depots:/opt/perforce/depots:rw \
  -v /server/mount/server:/opt/perforce/server:rw \
  --name=p4d \
  frozenfoxx/p4d:latest
```

If this is a fresh server, you'll want to create a superuser immediately:

```Shell
docker exec -it p4d /bin/bash

export P4PORT=localhost:1666
p4 user (fill in details for root)
p4 protect (this will make you the superuser if you are the first to connect)
p4 passwd (set root password)
```