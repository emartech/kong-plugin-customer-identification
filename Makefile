SHELL=/bin/bash
.PHONY: help up down restart clear-db build complete-restart publish test unit e2e dev-env ping ssh db

help: ## Show this help
	@echo "Targets:"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/\(.*\):.*##[ \t]*/    \1 ## /' | sort | column -t -s '##'

up: ## Start containers
	docker-compose up -d

down: ## Stops containers
	docker-compose down

restart: down up ## Restart containers

clear-db: ## Clears local db
	bash -c "rm -rf .docker"

build: ## Rebuild containers
	docker-compose build --no-cache

complete-restart: clear-db down up    ## Clear DB and restart containers

complete-restart-d:  ## Clear DB and restart containers
	bash -c "rm -rf .docker"
	docker-compose down
	docker-compose up

publish: ## Build and publish plugin to luarocks
	docker-compose run --rm kong bash -c "cd /kong-plugins && chmod +x publish.sh && ./publish.sh"

test: ## Run tests
	docker-compose run --rm kong bash -c "cd /kong && bin/kong migrations up && bin/busted /kong-plugins/spec"
	docker-compose down

dev-env: ## Creates API (testapi) and consumer (TestUser)
	bash -c "curl -i -X POST --url http://localhost:8001/services/ --data 'name=testapi' --data 'protocol=http' --data 'host=mockbin' --data 'port=8080' --data 'path=/request'"
	bash -c "curl -i -X POST --url http://localhost:8001/services/testapi/routes/ --data 'paths[]=/'"
	bash -c "curl -i -X POST --url http://localhost:8001/services/testapi/plugins/ --data 'name=customer-identification' --data 'config.source_headers=X-Suite-CustomerId' --data 'config.uri_matchers=/api/v2/internal/(.-)/' --data 'config.target_header=X-Suite-CustomerId'"

ping: ## Pings kong on localhost:8000
	bash -c "curl -i http://localhost:8000"

ssh: ## Pings kong on localhost:8000
	docker-compose run --rm kong bash

db: ## Access DB
	docker-compose run --rm kong bash -c "psql -h kong-database -U kong"