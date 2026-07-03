# bitrix-docker-env

Reusable local Docker environment for 1C-Bitrix CMS development and backup restore.

Clone the repository, set a local domain, put a Bitrix backup into `www/`, run `make up` and `make restore`, then complete restoration in the browser via the official `restore.php` wizard.

**Author:** Andrej Spinej  
**License:** [MIT](LICENSE)

## Stack

| Component | Image / version | Notes |
| --- | --- | --- |
| PHP-FPM | `php:8.3-fpm-bookworm` (build arg `PHP_VERSION`) | Custom image with Bitrix-oriented `php.ini` |
| MySQL | `mysql:8.0.36` (pinned via `MYSQL_IMAGE`) | Named volume `mysql-data`, init script for Bitrix user |
| nginx | `nginx:stable` | HTTPS, envsubst template, Bitrix URL rewrite |
| SSL | [mkcert](https://github.com/FiloSottile/mkcert) | Certs in `docker/nginx/certs/` (gitignored) |
| Orchestration | Docker Compose v2 | `compose.yaml`, healthchecks, `depends_on` conditions |

**PHP extensions installed by default:** `bcmath`, `exif`, `gd`, `intl`, `mysqli`, `pdo_mysql`, `soap`, `zip`.

**Additional extensions** via `PHP_EXTRA_EXTENSIONS` in `.env` (space-separated). `.env.example` includes `mbstring` (required by Bitrix). You can add more, e.g. `mbstring imagick redis xdebug`.

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
├── .github/
│   └── workflows/
│       └── ci.yml            # shell syntax, compose config, docker build
├── docker/
│   ├── nginx/
│   │   ├── certs/            # mkcert certificates (gitignored)
│   │   │   └── .gitkeep
│   │   └── templates/
│   │       └── default.conf.template
│   ├── php/
│   │   ├── Dockerfile
│   │   ├── php.ini
│   │   └── opcache.ini
│   └── mysql/
│       ├── initdb/
│       │   └── 01-bitrix-user.sh
│       └── my.cnf
├── scripts/
│   ├── doctor.sh             # Check Docker, mkcert, .env, hosts hint
│   ├── init-domain.sh        # mkcert install + SSL cert for DOMAIN
│   ├── download-restore.sh   # Fetch official restore.php into www/
│   └── restore-check.sh      # Verify restore.php and backup archives
└── www/                      # Bitrix site root (contents gitignored)
    └── .gitkeep
```

Sensitive paths (`www/*`, `docker/nginx/certs/*`, `.env`) are excluded from Git so backups, site files, and private certificates never reach a public repository.

## Requirements

- Docker Desktop or Docker Engine with Docker Compose v2
- Git Bash, WSL, macOS/Linux shell, or another shell that can run `bash`
- `make` for the short commands below
- `mkcert` for trusted local HTTPS certificates (required for `make cert` / `make up`)

On Windows, run shell scripts from Git Bash or WSL. If scripts fail with `bad interpreter`, check that Git did not convert line endings to CRLF. This repository includes `.gitattributes` to keep scripts as LF.

## Environment Variables

Copy the template and edit values for your machine:

```bash
cp .env.example .env
```

| Variable | Default | Description |
| --- | --- | --- |
| `PROJECT_NAME` | `bitrix-local` | Docker Compose project and container name prefix |
| `DOMAIN` | `bitrix.local` | Local HTTPS domain (must match hosts file and cert name) |
| `HTTP_PORT` | `80` | Host port mapped to nginx HTTP |
| `HTTPS_PORT` | `443` | Host port mapped to nginx HTTPS |
| `TIMEZONE` | `Europe/Moscow` | PHP and MySQL timezone |
| `PHP_VERSION` | `8.3` | PHP-FPM image tag (Docker build arg) |
| `PHP_EXTRA_EXTENSIONS` | `mbstring` | Space-separated extra PHP extensions, e.g. `mbstring imagick redis xdebug` |
| `UID` | `1000` | Linux/macOS user ID inside PHP container |
| `GID` | `1000` | Linux/macOS group ID inside PHP container |
| `XDEBUG_MODE` | `off` | Xdebug mode when `xdebug` is installed (`off`, `debug`, `develop`, …) |
| `MYSQL_IMAGE` | `mysql:8.0.36` | Pinned MySQL image (do not bump without testing) |
| `MYSQL_ROOT_PASSWORD` | `root` | MySQL root password |
| `MYSQL_DATABASE` | `bitrix` | Database name for Bitrix |
| `MYSQL_USER` | `bitrix` | Database user for Bitrix |
| `MYSQL_PASSWORD` | `bitrix` | Database password for Bitrix |

Example `.env` for a custom domain with extra PHP extensions:

```dotenv
DOMAIN=my-site.local
MYSQL_PASSWORD=change-me
PHP_EXTRA_EXTENSIONS=mbstring imagick redis xdebug
XDEBUG_MODE=debug
```

On macOS/Linux, set your real UID/GID to avoid file permission issues in `upload/` and `bitrix/cache/`:

```bash
id -u   # put into UID=
id -g   # put into GID=
```

After changing `PHP_EXTRA_EXTENSIONS`, rebuild the PHP image:

```bash
docker compose build php
```

## Quick Start

```bash
cp .env.example .env
# edit DOMAIN, passwords, and PHP_EXTRA_EXTENSIONS in .env

make init    # create .env if missing, run doctor
make up      # generate SSL cert, build and start containers
```

Add the domain to your hosts file (see [Local Domain](#local-domain)), then open:

```text
https://your-domain.local
```

`make up` automatically runs `make cert` first. If mkcert is not installed, certificate generation fails — install mkcert before `make up`.

## Local Domain

The environment uses the domain from `.env`. nginx and mkcert expect certificate files named:

```text
docker/nginx/certs/${DOMAIN}.pem
docker/nginx/certs/${DOMAIN}-key.pem
```

Add the domain to your hosts file:

```text
127.0.0.1 your-domain.local
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

`make doctor` and `scripts/init-domain.sh` print the exact record for your configured domain. Scripts do not silently edit system files without your control.

## HTTPS

Install [mkcert](https://github.com/FiloSottile/mkcert), then either run `make up` (cert is included) or regenerate manually:

```bash
make cert
```

`scripts/init-domain.sh`:

- runs `mkcert -install`
- creates a certificate for `${DOMAIN}` and `*.${DOMAIN}`
- writes files to `docker/nginx/certs/` (gitignored)

If the browser still shows an SSL warning:

```bash
mkcert -install
make cert
docker compose restart nginx
```

## Restore a Bitrix Backup

Full workflow:

```bash
cp .env.example .env
# set DOMAIN and MYSQL_PASSWORD

make init
# put backup archive into ./www/

make up
make restore
```

`make restore`:

1. Downloads the official `restore.php` from 1C-Bitrix into `www/` (if missing).
2. Checks that at least one backup archive exists in `www/`.

Supported archive extensions: `.tar`, `.tar.gz`, `.tgz`, `.tar.bz2`, `.tar.xz`, `.zip`.

Open:

```text
https://your-domain.local/restore.php
```

Use these database settings in the Bitrix restore wizard (values come from `.env`):

```text
Host: mysql
Database: <MYSQL_DATABASE>
User: <MYSQL_USER>
Password: <MYSQL_PASSWORD>
```

Important: inside Docker the database host is `mysql`, not `localhost`.

After restore, delete `restore.php` and backup archives from `www/`. The files are ignored by Git, but they must not remain available from the browser.

## Useful Commands

```bash
make doctor         # check Docker, compose, mkcert, .env, hosts hint
make init           # create .env from .env.example and run doctor
make cert           # generate mkcert certificate for DOMAIN
make up             # cert + build + start containers (--wait)
make down           # stop containers
make restart        # restart all containers
make logs           # follow logs
make shell          # open bash in PHP container
make mysql          # connect to MySQL CLI
make restore        # download restore.php and check backup files
make restore-check  # verify restore.php and archives only
make config         # validate Compose config
make build          # build images
make clean          # stop containers and remove Docker volumes
```

`make clean` removes Docker volumes, including the MySQL database volume. It does not delete files from `www/`.

## PHP and nginx Defaults

PHP limits in `docker/php/php.ini` (oriented toward large Bitrix backups):

- `memory_limit = 512M`
- `upload_max_filesize = 1024M`
- `post_max_size = 1024M`
- `max_execution_time = 300`

nginx in `docker/nginx/templates/default.conf.template`:

- HTTP → HTTPS redirect
- Bitrix routing via `/bitrix/urlrewrite.php`
- `client_max_body_size 1024M`
- Blocks PHP execution in `upload/` and Bitrix cache directories
- Denies hidden files (except `.well-known`)

## MySQL Notes

This template intentionally uses `mysql:8.0.36`.

Do not replace it with MySQL 8.4 or 9.0 without testing your Bitrix project. Older Bitrix backups and PHP clients may require `mysql_native_password`, while newer MySQL versions can disable or remove it.

On first start with an empty volume, `docker/mysql/initdb/01-bitrix-user.sh`:

- creates the database and Bitrix user
- uses `mysql_native_password` when the plugin is available
- falls back to the default MySQL authentication plugin otherwise

`docker/mysql/my.cnf` sets `utf8mb4`, increased `max_allowed_packet`, and Bitrix-friendly InnoDB options.

## Optional Extensions

The base PHP image stays small. Enable extra extensions only when needed:

```dotenv
PHP_EXTRA_EXTENSIONS=mbstring imagick redis xdebug
XDEBUG_MODE=debug
```

Then rebuild:

```bash
docker compose build php
```

Add Redis, Memcached, Sphinx, Elasticsearch, or Traefik later via `compose.override.yaml` or Docker Compose profiles when a specific project requires them.

## CI

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on push and pull request:

- `bash -n` on all shell scripts
- `docker compose config`
- `docker compose build`

## Troubleshooting

| Problem | What to check |
| --- | --- |
| `make up` fails on cert step | Install mkcert; run `make cert` separately to see the error |
| Port 80 or 443 is busy | Change `HTTP_PORT` / `HTTPS_PORT` in `.env`, or stop the conflicting service |
| Domain does not open | Hosts file entry for `DOMAIN`; run `make doctor` |
| SSL warning in browser | `mkcert -install`, then `make cert`, then `docker compose restart nginx` |
| MySQL connection fails in restore wizard | Host must be `mysql`, not `localhost` |
| `make restore` — no archive found | Put `.tar.gz`, `.zip`, or other supported archive into `./www/` |
| File permission issues on Linux/macOS | Set `UID` and `GID` in `.env` to output of `id -u` / `id -g` |
| Shell scripts fail on Windows | Use Git Bash or WSL; ensure LF line endings (`.gitattributes`) |
| PHP extension missing | Add it to `PHP_EXTRA_EXTENSIONS` and run `docker compose build php` |
| MySQL auth errors after image upgrade | Do not bump `MYSQL_IMAGE` without testing; use `make clean` only if you accept data loss |

## License

This project is licensed under the [MIT License](LICENSE) — free to use in private and commercial Bitrix projects without copyleft obligations.
