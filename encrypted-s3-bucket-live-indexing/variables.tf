variable "cs_external_id" {
  description = "chaossearch.io - String: External id (customer id) for bucket creations and assume role"
  type        = string
}

variable "cs_data_bucket" {
  description = "chaossearch.io - String: Bucket name to be created to index data out of"
  type        = string
}

variable "sqs_queue" {
  description = "chaossearch.io - Boolean: Should there be an sqs queue configured for live update"
  type        = bool
  default     = true
}
