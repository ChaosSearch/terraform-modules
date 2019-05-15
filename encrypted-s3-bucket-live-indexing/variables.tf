variable "region" {
  description = "Default region"
  default     = "us-east-1"
}

variable "cs_external_id" {
  description = "chaossearch.io - String: External id (customer id) for bucket creations and assume role"
}

variable "cs_data_bucket" {
  description = "chaossearch.io - String: Bucket name to be created to index data out of"
}

variable "sqs_queue" {
  description = "chaossearch.io - Boolean: Should there be an sqs queue configured for live update"
}
