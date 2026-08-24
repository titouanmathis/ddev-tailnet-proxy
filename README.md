# ddev-tailnet-proxy

Expose running [DDEV](https://ddev.com/) projects on stable HTTPS ports of one Tailscale node.

The tool starts an Nginx container on the DDEV router network. Each running project receives a stable localhost port, such as `19001`. Nginx sends requests to `project.ddev.site` through `ddev-router` and rewrites canonical-host redirects, cookies, and common text responses to the Tailscale node URL. Tailscale Serve then exposes that localhost port as `https://node.tailnet.ts.net:19001`.

## Requirements

- Linux with systemd
- Docker and a running DDEV project
- Tailscale, logged in on this host
- `jq`
- Permission to run `sudo`

The installed service runs as root. This is required because `tailscale serve` changes node-level Tailscale configuration. Root access also lets it inspect Docker directly. It does not use the DDEV CLI or a user home directory.

The proxy uses the Docker network `ddev_default`. This is the DDEV default. Start a DDEV project before the first refresh so the network exists.

## Install with Mise

Add this to `mise.toml`:

```toml
[tools]
"github:titouanmathis/ddev-tailnet-proxy" = "0.1.4"
```

Then install the system service:

```sh
sudo ddev-tailnet-proxy service install
```

Mise's GitHub backend finds the executable at `bin/ddev-tailnet-proxy` in the release archive.

## Manual release install

Download the release archive and its checksum from GitHub. Verify it, then put `bin/ddev-tailnet-proxy` on your `PATH`:

```sh
sha256sum -c ddev-tailnet-proxy-0.1.4.tar.gz.sha256
tar -xzf ddev-tailnet-proxy-0.1.4.tar.gz
sudo install -m 755 ddev-tailnet-proxy-0.1.4/bin/ddev-tailnet-proxy /usr/local/bin/ddev-tailnet-proxy
sudo ddev-tailnet-proxy service install
```

`service install` installs a second copy at `/usr/local/bin/ddev-tailnet-proxy`, writes two units to `/etc/systemd/system`, enables the timer, and runs an immediate refresh.

## Commands

```text
sudo ddev-tailnet-proxy refresh
ddev-tailnet-proxy status
sudo ddev-tailnet-proxy config set-node-dns NAME
sudo ddev-tailnet-proxy config unset-node-dns
sudo ddev-tailnet-proxy config show
sudo ddev-tailnet-proxy service install
sudo ddev-tailnet-proxy service uninstall
sudo ddev-tailnet-proxy service status
```

Run `refresh`, `config`, and `service` commands with `sudo`. `status` reads a public summary written by the root-owned service, so it does not require root.

The tool normally detects the node name from `tailscale status --json`. If your Tailscale version does not return `Self.DNSName`, set it explicitly:

```sh
sudo ddev-tailnet-proxy config set-node-dns my-node.example.ts.net
```

The timer runs one minute after boot and every two minutes after that. Run `sudo ddev-tailnet-proxy refresh` when you need an immediate update.

## State and security

| Path | Purpose | Mode |
| --- | --- | --- |
| `/etc/ddev-tailnet-proxy/config` | Optional DNS override and settings | root, `0600` |
| `/var/lib/ddev-tailnet-proxy/ports.tsv` | Stable project-to-port assignments | root, `0644` |
| `/var/lib/ddev-tailnet-proxy/served-ports.tsv` | Tailscale Serve routes owned by this tool | root, `0600` |
| `/var/lib/ddev-tailnet-proxy/status` | Public status summary | root, `0644` |
| `/var/lib/ddev-tailnet-proxy/nginx.conf` | Generated Nginx configuration | root, `0600` |
| `/var/log/ddev-tailnet-proxy` | Reserved service log directory | root, `0750` |

A stopped project keeps its port assignment. Its port is not proxied or served until the project runs again. Projects that bind their own web container to `0.0.0.0` or `::` are skipped. They already have a direct host exposure and may use incompatible canonical-port settings.

The generated Nginx configuration disables upstream TLS verification because DDEV uses local certificates. The connection remains inside the Docker network. Tailscale terminates HTTPS access for Tailnet peers on each served port.

## Release

No Node.js, npm, or Make is required. Create a GitHub release asset with standard Linux utilities:

```sh
scripts/release.sh 0.1.4
```

This creates `dist/ddev-tailnet-proxy-0.1.4.tar.gz` and a checksum file that verifies when downloaded beside the archive. Upload both files to a GitHub release with the matching tag.

Run the minimal validation:

```sh
tests/validate.sh
```

## License

MIT. See [LICENSE](LICENSE).
