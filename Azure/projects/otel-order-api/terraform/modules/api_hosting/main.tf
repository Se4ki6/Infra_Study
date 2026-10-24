resource "azurerm_container_app_environment" "this" {
  name                       = "cae-otel-order-api-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = var.tags
}

resource "azurerm_container_registry" "this" {
  name                = var.container_registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "uai-otel-order-api-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_container_app" "this" {
  count = var.enable_api ? 1 : 0

  name                         = "ca-otel-order-api-${var.environment}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  registry {
    server   = azurerm_container_registry.this.login_server
    identity = azurerm_user_assigned_identity.this.id
  }

  secret {
    name  = "application-insights-connection-string"
    value = var.application_insights_connection_string
  }

  secret {
    name  = "blob-connection-string"
    value = var.blob_connection_string
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "api"
      image  = "${azurerm_container_registry.this.login_server}/otel-order-api:${var.image_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "application-insights-connection-string"
      }

      env {
        name        = "Blob__ConnectionString"
        secret_name = "blob-connection-string"
      }

      env {
        name  = "Blob__ContainerName"
        value = var.blob_container_name
      }

      env {
        name  = "OTEL_SERVICE_NAME"
        value = "otel-order-api"
      }

      env {
        name  = "ASPNETCORE_URLS"
        value = "http://0.0.0.0:8080"
      }

      readiness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/health"
      }

      liveness_probe {
        transport        = "HTTP"
        port             = 8080
        path             = "/health"
        initial_delay    = 10
        interval_seconds = 10
      }
    }
  }

  ingress {
    external_enabled           = true
    target_port                = 8080
    transport                  = "http"
    allow_insecure_connections = false

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  depends_on = [azurerm_role_assignment.acr_pull]
}
