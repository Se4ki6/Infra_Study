PORT ?= 5080
OTLP_ENDPOINT ?= http://localhost:4317
RUN_PID_FILE := .otel-order-api.pid
API_PROJECT := src/Api/OtelOrderApi.Api.csproj

.PHONY: dev api stop build

dev:
	docker compose up -d azurite aspire-dashboard
	@attempt=0; \
	while [ "$$attempt" -lt 15 ]; do \
		login_url=$$(docker compose logs --no-color --no-log-prefix aspire-dashboard 2>/dev/null | sed -n 's/^Login URL:[[:space:]]*//p' | tail -n 1); \
		if [ -n "$$login_url" ]; then printf 'Aspire Dashboard login URL: %s\n' "$$login_url"; break; fi; \
		attempt=$$((attempt + 1)); sleep 1; \
	done
	OTEL_EXPORTER_OTLP_ENDPOINT=$(OTLP_ENDPOINT) OTEL_EXPORTER_OTLP_PROTOCOL=grpc OTEL_SERVICE_NAME=otel-order-api bash scripts/run-api.sh dotnet run --project $(API_PROJECT) --urls http://localhost:$(PORT)

api:
	bash scripts/run-api.sh dotnet run --project $(API_PROJECT) --urls http://localhost:$(PORT)

stop:
	@if [ -f $(RUN_PID_FILE) ]; then \
		api_pid=$$(cat $(RUN_PID_FILE)); \
		if kill -0 "$$api_pid" 2>/dev/null; then \
			kill -TERM -- "-$$api_pid" 2>/dev/null || true; \
			for attempt in 1 2 3 4 5 6 7 8 9 10; do \
				kill -0 "$$api_pid" 2>/dev/null || break; \
				sleep 0.1; \
			done; \
		fi; \
		rm -f $(RUN_PID_FILE); \
	fi
	docker compose down

build:
	dotnet build $(API_PROJECT)
