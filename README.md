# Assignment 2 – Dockerized Diagnostic CLI

A Bash diagnostic CLI packaged as a lightweight (Alpine) Docker image.

## Requirements
Docker (with the Compose plugin) on Linux. No cloud services needed.

## Setup / Build
```bash
git clone <your-repository-url>
cd <repository>
chmod +x grade.sh test.sh app/*.sh
docker build -t diagnostic-tool .
```

## Usage
```bash
docker run --rm diagnostic-tool help
docker run --rm diagnostic-tool system
docker run --rm diagnostic-tool disk
docker run --rm diagnostic-tool network localhost
```
With Docker Compose:
```bash
docker compose run --rm diagnostic system
docker compose run --rm diagnostic network localhost
```

| Command | Description |
|---|---|
| `system` | hostname, user, OS, kernel, uptime, CPU, memory |
| `network <host>` | validates, resolves and pings a host |
| `disk [path]` | disk usage (`df -h`), default `/` |
| `help` | usage text |

### Exit codes
`0` success · `1` operational failure (e.g. host cannot be resolved) · `2` invalid command, missing argument or invalid input.

## Docker practices
- Small base image (`alpine`), only `bash` installed, `--no-cache`.
- Application copied into the image, scripts made executable.
- Runs as a non-root user; `ENTRYPOINT` = the CLI, default `CMD` = `help`.
- `.dockerignore` excludes `.git`, logs, temp files, docs and tests.
- Compose file runs the container read-only with a tmpfs `/tmp`.
- `app/health-check.sh` verifies the CLI is usable.

## Testing
```bash
./test.sh      # builds the image and runs 10 tests (help, system, disk, network, invalid input)
./grade.sh     # instructor grader
```

## Assumptions
- Ping failure is informational; `network` succeeds when the host resolves.
- Docker daemon is running and the user may run `docker`.
- No secrets are stored in this repository.
