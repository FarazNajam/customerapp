locals {
    role_assignments = {
 kv-secrets-reader = {
  principal_key = "frontend"
  scope = module.key_vault.key_vault_ids["infraguardian"]
  role_definition_name = "Key Vault Secrets User"
 }

 storage-reader = {
  principal_key = "frontend"
  scope = module.storage_account.storage_account_ids["infraguardian"]
  role_definition_name = "Storage Blob Data Reader"
 }
}
}