# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "search_location" {
  description = "Azure region for AI Search (override if primary region is out of capacity)"
  type        = string
  default     = ""
}

variable "principal_id" {
  description = "Object ID of the deploying user/service principal for role assignments"
  type        = string
}

variable "principal_type" {
  description = "Type of the deploying principal"
  type        = string
  default     = "User"
  validation {
    condition     = contains(["User", "ServicePrincipal"], var.principal_type)
    error_message = "Must be 'User' or 'ServicePrincipal'."
  }
}

variable "openai_model_name" {
  description = "OpenAI model name from the Azure AI model catalog"
  type        = string
  default     = "gpt-5.4"
}

variable "openai_model_version" {
  description = "OpenAI model version"
  type        = string
  default     = "2026-03-05"
}

variable "openai_capacity" {
  description = "Provisioned throughput in thousands of tokens per minute (TPM)"
  type        = number
  default     = 10
}

variable "fabric_sku" {
  description = "Fabric capacity SKU (F4 = 4 CUs)"
  type        = string
  default     = "F4"
}

variable "fabric_admin_members" {
  description = "UPNs of Fabric capacity administrators"
  type        = list(string)
}

variable "enable_private_networking" {
  description = "Provision VNet + private endpoints. Disables public access on AI Services and Search."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    SecurityControl = "Ignore"
    Project         = "discount-tire-store-advisor"
  }
}
