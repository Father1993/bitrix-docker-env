# bitrix-docker-env

Reusable local Docker environment for 1C-Bitrix CMS development and backup restore.

Clone the repository, set a local domain, put a Bitrix backup into `www/`, run `make up` and `make restore`, then complete restoration in the browser via the official `restore.php` wizard.

**Author:** Andrej Spinej  
**License:** [MIT](LICENSE)

## Stack

- PHP-FPM 8.3, configurable with `PHP_VERSION`
- MySQL `8.0.36`, pinned for reproducibility
- nginx with HTTPS and dynamic domain configuration
- Local SSL certificates generated with `mkcert`
- Docker Compose with healthchecks

## Project Structure

```text
bitrix-docker-env/
├── .env.example              # Environment template (copy to .env)
├── .gitattributes            # LF line endings for shell scripts
├── .gitignore                # PHP + Docker + Bitrix exclusions
├── LICENSE                   # MIT License
├── Makefile                  # Short commands: up, restore, cert, …
├── README.md
├── compose.yaml              # nginx, php-fpm, mysql services
├── docker/
│   ├── nginx/
│   │   ├── certs/            # mkcert certificates (gitignored)
│   │   └── templates/        # nginx envsubst templates
│   ├── php/
│   │   ├── Dockerfile
│   │   ├── php.ini
│   │   └── opcache.ini
│   └── mysql/
│       ├── initdb/           # Bitrix user bootstrap on first start
│       └── my.cnf
├── scripts/
│   ├── doctor.sh             # Check Docker, mkcert, .env
│   ├── init-domain.sh        # Generate SSL cert for DOMAIN
│   ├── download-restore.sh   # Fetch official restore.php
│   └── restore-check.sh      # Verify backup archive in www/
└── www/                      # Bitrix site root (gitignored contents)
    └── .gitkeep
```

Sensitive paths (`www/*`, `docker/nginx/certs/*`, `.env`) are excluded from Git so backups, site files, and private certificates never reach a public repository.

## Requirements

- Docker Desktop or Docker Engine with Docker Compose v2
- Git Bash, WSL, macOS/Linux shell, or another shell that can run `bash`
- `make` for the short commands below
- `mkcert` for trusted local HTTPS certificates

On Windows, run shell scripts from Git Bash or WSL. If scripts fail with `bad interpreter`, check that Git did not convert line endings to CRLF. This repository includes `.gitattributes` to keep scripts as LF.

## Environment Variables

Copy the template and edit values for your machine:

```bash
cp .env.example .env
```

| Variable | Default | Description |
| --- | --- | --- |
| `PROJECT_NAME` | `bitrix-local` | Docker Compose project and container name prefix |
| `DOMAIN` | `bitrix.local` | Local HTTPS domain (must match hosts file) |
| `HTTP_PORT` | `80` | Host port mapped to nginx HTTP |
| `HTTPS_PORT` | `443` | Host port mapped to nginx HTTPS |
| `TIMEZONE` | `Europe/Moscow` | PHP and MySQL timezone |
| `PHP_VERSION` | `8.3` | PHP-FPM image tag (build arg) |
| `UID` | `1000` | Linux/macOS user ID inside PHP container |
| `GID` | `1000` | Linux/macOS group ID inside PHP container |
| `XDEBUG_MODE` | `off` | Xdebug mode (`off`, `debug`, `develop`, …) |
| `MYSQL_IMAGE` | `mysql:8.0.36` | Pinned MySQL image (do not bump without testing) |
| `MYSQL_ROOT_PASSWORD` | `root` | MySQL root password |
| `MYSQL_DATABASE` | `bitrix` | Database name for Bitrix |
| `MYSQL_USER` | `bitrix` | Database user for Bitrix |
| `MYSQL_PASSWORD` | `bitrix` | Database password for Bitrix |

Example `.env` for a custom domain:

```dotenv
DOMAIN=my-site.local
MYSQL_PASSWORD=change-me
```

On macOS/Linux, set your real UID/GID to avoid file permission issues in `upload/` and `bitrix/cache/`:

```bash
id -u   # put into UID=
id -g   # put into GID=
```

## Quick Start

```bash
cp .env.example .env
# edit DOMAIN and passwords in .env

make init
make up
```

Open:

```text
https://my-site.local
```

## Local Domain

The environment uses the domain from `.env`.

Add the domain to your hosts file:

```text
127.0.0.1 my-site.local
```

Windows hosts file:

```text
C:\Windows\System32\drivers\etc\hosts
```

Open PowerShell or Notepad as Administrator before editing it.

Linux/macOS hosts file:

```text
/etc/hosts
```

`scripts/init-domain.sh` prints the exact record for your configured domain. It does not silently edit system files without your control.

## HTTPS

Install `mkcert` and run:

```bash
make cert
```

The certificate is generated in `docker/nginx/certs/` and is ignored by Git.

If the browser still shows an SSL warning, run:

```bash
mkcert -install
make cert
docker compose restart nginx
```

## Restore a Bitrix Backup

1. Put the Bitrix backup archive into `www/`.
2. Run:

```bash
make up
make restore
```

`make restore` downloads the official `restore.php` if it is missing and checks that at least one backup archive exists in `www/`.

Open:

```text
https://your-domain.local/restore.php
```

Use these database settings in the Bitrix restore wizard:

```text
Host: mysql
Database: bitrix
User: bitrix
Password: value from MYSQL_PASSWORD in .env
```

Important: inside Docker the database host is `mysql`, not `localhost`.

After restore, delete `restore.php` and backup archives from `www/`. The files are ignored by Git, but they must not remain available from the browser.

## Useful Commands

```bash
make doctor        # check required local tools and important config
make init          # create .env from .env.example and run doctor
make cert          # generate mkcert certificate for DOMAIN
make up            # build and start containers
make down          # stop containers
make logs          # follow logs
make shell         # open bash in PHP container
make mysql         # connect to MySQL
make restore       # download restore.php and check backup files
make config        # validate Compose config
make build         # build images
make clean         # stop containers and remove Docker volumes
```

`make clean` removes Docker volumes, including the MySQL database volume. It does not delete files from `www/`.

## MySQL Notes

This template intentionally uses `mysql:8.0.36`.

Do not replace it with MySQL 8.4 or 9.0 without testing your Bitrix project. Older Bitrix backups and PHP clients may require `mysql_native_password`, while newer MySQL versions can disable or remove it.

The MySQL init script creates the Bitrix database user and tries to use `mysql_native_password` when available. This keeps compatibility with older projects without relying on deprecated global server flags.

## Optional Extensions

The base PHP image is kept small and predictable. Enable extra PHP extensions only when a specific project needs them:

```dotenv
PHP_EXTRA_EXTENSIONS=imagick redis xdebug
XDEBUG_MODE=debug
```

Then rebuild:

```bash
docker compose build php
```

Add Redis, Memcached, Sphinx, Elasticsearch, or Traefik later via `compose.override.yaml` or Docker Compose profiles when a specific project requires them.

## Troubleshooting

- Port 80 or 443 is busy: change `HTTP_PORT` and `HTTPS_PORT` in `.env`, or stop the service using those ports.
- Domain does not open: check your hosts file and run `make cert`.
- MySQL connection fails in restore wizard: use host `mysql`, not `localhost`.
- File permission issues on Linux/macOS: set `UID` and `GID` in `.env` to your real user values.
- Shell scripts fail on Windows: ensure line endings are LF and run commands from Git Bash or WSL.
- Browser does not trust the certificate: run `mkcert -install`, regenerate certificate, and restart nginx.

## License

This project is licensed under the [MIT License](LICENSE) — free to use in private and commercial Bitrix projects without copyleft obligations.
