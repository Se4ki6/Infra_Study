PORT ?= 5080
API_PROJECT := src/Api/OtelOrderApi.Api.csproj

.PHONY: dev api stop build

dev:
	docker compose up -d azurite
	dotnet run --project $(API_PROJECT) --urls http://localhost:$(PORT)

api:
	dotnet run --project $(API_PROJECT) --urls http://localhost:$(PORT)

stop:
	docker compose down

build:
	dotnet build $(API_PROJECT)
