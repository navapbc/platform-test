locals {
  documentai_api_config = {
    document_metadata_table_name = "${var.app_name}-${var.environment}-document-metadata"
  }
}