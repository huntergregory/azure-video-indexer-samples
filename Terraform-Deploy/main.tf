# create random string
resource "random_string" "random" {
  length      = 4
  number      = true
  lower       = true
  upper       = false
  special     = false
  min_numeric = 1
}

# create locals
locals {
  arm_file_path = "./arm/vi.template.json"
  required_tags = {
    name        = var.name
    environment = var.environment
    uid         = random_string.random.id
  }
}

# create resource group
resource "azurerm_resource_group" "vi-rg" {
  name     = var.resource_group_name
  location = var.location
}


# create storage for media services
resource "azurerm_storage_account" "media_storage" {
  location            = azurerm_resource_group.vi-rg.location
  resource_group_name = azurerm_resource_group.vi-rg.name
  tags                = var.tags

  account_tier              = "Standard"
  account_replication_type  = "LRS"
  name                      = "${var.prefix}${random_string.random.result}"
  enable_https_traffic_only = true
  depends_on = [
    azurerm_resource_group.vi-rg,
  ]
}

# create media services
resource "azurerm_media_services_account" "media" {
  location            = azurerm_resource_group.vi-rg.location
  resource_group_name = azurerm_resource_group.vi-rg.name
  tags                = var.tags
  name                = "${var.prefix}${random_string.random.result}"
  storage_account {
    id         = azurerm_storage_account.media_storage.id
    is_primary = true
  }
  depends_on = [
    azurerm_storage_account.media_storage,
  ]
}

# create user assigned managed identity
resource "azurerm_user_assigned_identity" "vi" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "${var.prefix}-${random_string.random.result}-mi"
  depends_on = [
    azurerm_resource_group.vi-rg,
  ]
}

resource "azurerm_role_assignment" "vi_mediaservices_access" {
  scope                = azurerm_media_services_account.media.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.vi.principal_id
  depends_on = [
    azurerm_media_services_account.media,
  ]
}

data "template_file" "workflow" {
  template = file(local.arm_file_path)
}

# deploy video indexer (arm template)
resource "azurerm_resource_group_template_deployment" "vi" {
  resource_group_name = var.resource_group_name
  parameters_content = jsonencode({
    "name"                          = { value = "${var.prefix}${random_string.random.result}" },
    "managedIdentityResourceId"     = { value = azurerm_user_assigned_identity.vi.id },
    "mediaServiceAccountResourceId" = { value = azurerm_media_services_account.media.id }
    "tags"                          = { value = var.tags }
  })

  template_content = data.template_file.workflow.template

  # The filemd5 forces this to run when the file is changed
  # this ensures the keys are up-to-date
  name            = "avam-${filemd5(local.arm_file_path)}"
  deployment_mode = "Incremental"
  depends_on = [
    azurerm_media_services_account.media,
    azurerm_user_assigned_identity.vi,
    azurerm_role_assignment.vi_mediaservices_access
  ]
}
