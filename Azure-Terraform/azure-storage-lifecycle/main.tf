provider "azurerm" {
  features {}

  subscription_id = "eb42806a-9a76-49bd-8024-373de52d371d"
}

# ------------------------------
# ✅ Create Resource Group
# ------------------------------
resource "azurerm_resource_group" "san_storage_rg" {
  name     = "san-storage-rg"
  location = "East US"
}

# ------------------------------
# ✅ Create Storage Account
# ------------------------------
resource "azurerm_storage_account" "san_storage_account" {
  name                     = "sanstorageaccount2025"
  resource_group_name      = azurerm_resource_group.san_storage_rg.name
  location                 = azurerm_resource_group.san_storage_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }
}

# ------------------------------
# ✅ Create Storage Container (Like S3 Bucket)
# ------------------------------
resource "azurerm_storage_container" "san_container" {
  name                  = "my-container"
  storage_account_name  = azurerm_storage_account.san_storage_account.name
  container_access_type = "private"
}

# ------------------------------
# ✅ FINAL STORAGE MANAGEMENT POLICY WITHOUT ERRORS
# ------------------------------
resource "azurerm_storage_management_policy" "san_policy" {
  storage_account_id = azurerm_storage_account.san_storage_account.id

  rule {
    name    = "move-to-cool-storage"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
      }
    }
  }

  rule {
    name    = "move-to-archive"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_archive_after_days_since_modification_greater_than = 60
      }
    }
  }

  rule {
    name    = "delete-after-365-days"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 365
      }
    }
  }
}

# ------------------------------
# ✅ OUTPUTS (FOR VERIFICATION)
# ------------------------------
output "storage_account_name" {
  value = azurerm_storage_account.san_storage_account.name
}

output "container_name" {
  value = azurerm_storage_container.san_container.name
}

output "resource_group_name" {
  value = azurerm_resource_group.san_storage_rg.name
}
