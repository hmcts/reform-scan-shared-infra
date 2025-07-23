variable "product" {}

variable "location" {
  default = "UK South"
}

variable "application_type" {
  default     = "web"
  description = "Type of Application Insights (Web/Other)"
}

variable "env" {}

variable "subscription" {}

variable "mgmt_subscription_id" {}

variable "common_tags" {
  type = map(any)
}

variable "tenant_id" {}

variable "jenkins_AAD_objectId" {
  type        = string
  description = "(Required) The Azure AD object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies."
}

variable "managed_identity_api_mgmt" {
  default = ""
}

variable "managed_identity_cft_api_mgmt" {
  default = ""
}

variable "external_hostname" {
  type        = string
  default     = "platform.hmcts.net"
  description = "Ending of hostname. Subdomains will be resolved in declaration of locals"
}

variable "enable_staging_account" {
  default = 0
}

variable "aks_subscription_id" {}

variable "storage_account_repl_type" {
  default = "LRS"
}

variable "staging_storage_account_repl_type" {
  default = "LRS"
}

variable "sku_service_bus" {
  description = "Basic, Standard or Premium"
  default     = "Standard"
}

variable "zone_redundant_service_bus" {
  default = false
}

variable "capacity_service_bus" {
  default = 0
}
