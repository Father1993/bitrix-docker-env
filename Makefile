SHELL := bash

ifneq (,$(wildcard .env))
include .env
export
endif

DOMAIN ?= bitrix.local

.PHONY: init doctor cert up down restart logs shell mysql restore restore-check config build clean

init:
	@if [ ! -f .env ]; then cp .env.example .env && echo "Created .env from .env.example"; else echo ".env already exists"; fi
	@$(MAKE) doctor

doctor:
	@bash scripts/doctor.sh

cert:
	@bash scripts/init-domain.sh

up: cert
	docker compose up -d --build --wait
	@docker compose exec -T mysql mysql -uroot -p"$${MYSQL_ROOT_PASSWORD:-root}" -e \
		"GRANT SESSION_VARIABLES_ADMIN ON *.* TO '$${MYSQL_USER:-bitrix}'@'%'; FLUSH PRIVILEGES;" 2>/dev/null || true
	@echo "Ready: https://$(DOMAIN)"

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

shell:
	docker compose exec php bash

mysql:
	docker compose exec mysql mysql -u"$${MYSQL_USER:-bitrix}" -p"$${MYSQL_PASSWORD:-bitrix}" "$${MYSQL_DATABASE:-bitrix}"

restore:
	@bash scripts/download-restore.sh
	@bash scripts/restore-check.sh
	@echo "Open: https://$(DOMAIN)/restore.php"

restore-check:
	@bash scripts/restore-check.sh

config:
	docker compose config

build:
	docker compose build

clean:
	docker compose down -v --remove-orphans
	@echo "Docker volumes removed. Files in ./www are kept."
