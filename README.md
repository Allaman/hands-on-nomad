# Hands-on Nomad

Source files for my [Hands-on Nomad](https://rootknecht.net/blog/hands-on-nomad/) blog post.

## Install Nomad on a single node

[bootstrap.sh](./bootstrap.sh) (tested on Debian 11 server) installs Nomad, Docker, and OpenJDK for the example workloads.

Add a file `.envrc` with the following content:

```
export NOMAD_TOKEN=<output from the bootstrap.sh script>
export NOMAD_ADDR=<IP of your server>
```

This is not a production-ready setup!

## Deploy example workloads

- `make hello`: Deploy a dockerized hello world app (3 instances).
- `make traefik`: Deploy Traefik as Proxy/LB.
- `make blueprint`: Deploy [ralfhecktor/architecture-blueprint](https://github.com/ralfhecktor/architecture-blueprint) (JVM based workload) in namespace dev and also create a policy and token with restricted permissions.

If you deploy all workloads the following URLs are exposed:

- `http://<IP>/hello` - hello world with default load balancing
- `http://<IP>/blueprint` - blueprint app
- `http://<IP>/dashboard` - Traefik dashboard (`admin:admin`)

## Misc

- `make anonymous`: Allow anonymous full access to the cluster (⚠️)
- `make status`: Status of your workloads
- `make ui`: Open Nomad UI in your default browser
