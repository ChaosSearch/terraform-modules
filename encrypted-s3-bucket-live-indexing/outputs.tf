output "cs_data_bucket_bucket" {
  value = "${aws_s3_bucket.cs_data_bucket.id} encrypted with kms ${aws_kms_key.cs_data_bucket_key.0.id}"
}

output "cs_logging_serverside_role" {
  value = "${aws_iam_role.cs_logging_server_side_role.arn}"
}

output "sqs_live_logging_arn" {
  value = "SQS Live logging arn: ${aws_sqs_queue.cs_s3_bucket_sqs.0.arn}"
}
