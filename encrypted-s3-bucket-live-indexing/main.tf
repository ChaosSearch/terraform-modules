##
## Remote state us-east-1
##

resource "aws_s3_bucket" "cs_data_bucket" {
  provider = "aws.us-east-1"

  bucket = "${var.cs_data_bucket}-${var.region}"
  acl    = "private"

  force_destroy = false

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.cs_data_bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "cleanup_after_30_days"
    enabled = true

    abort_incomplete_multipart_upload_days = 7

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 31
    }
  }

  tags {
    Name     = "${var.cs_data_bucket}-${var.region}"
  }
}

resource "aws_sqs_queue" "cs_s3_bucket_sqs" {
  count = "${var.sqs_queue ? 1 : 0}"

  provider = "aws.us-east-1"

  name                      = "s3-sqs-${var.cs_data_bucket}-${var.region}"
  max_message_size          = 2048
  message_retention_seconds = 86400
  visibility_timeout_seconds = 480

  tags = {
    Bucket = "${var.cs_data_bucket}-${var.region}"
  }
}

resource "aws_sqs_queue_policy" "cs_s3_bucket_sqs" {
  count = "${var.sqs_queue ? 1 : 0}"

  provider = "aws.us-east-1"

  queue_url = "${aws_sqs_queue.cs_s3_bucket_sqs.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.cs_s3_bucket_sqs.arn}",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.cs_data_bucket.arn}" }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [ "${aws_iam_role.cs_logging_server_side_role.arn}" ]
      },
      "Action": "sqs:*",
      "Resource": "${aws_sqs_queue.cs_s3_bucket_sqs.arn}"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "cs_data_bucket_notification" {
  count = "${var.sqs_queue ? 1 : 0}"
  depends_on = ["aws_sqs_queue_policy.cs_s3_bucket_sqs"]

  provider = "aws.us-east-1"

  bucket = "${aws_s3_bucket.cs_data_bucket.id}"

  queue {
    queue_arn = "${aws_sqs_queue.cs_s3_bucket_sqs.arn}"
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_kms_key" "cs_data_bucket_key" {
  provider = "aws.us-east-1"

  description             = "This key is used to encrypt ${var.cs_data_bucket}-${var.region}"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "cs_data_bucket_key" {
  provider = "aws.us-east-1"

  name          = "alias/cs_${var.cs_data_bucket}_${var.region}"
  target_key_id = "${aws_kms_key.cs_data_bucket_key.key_id}"
}


##
## IAM Role + Policy
##

resource "aws_iam_role" "cs_logging_server_side_role" {
  provider = "aws.us-east-1"

  name = "cs_logging_server_side_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::515570774723:root"
      },
      "Effect": "Allow",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${var.cs_external_id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cs_logging_server_side_role_policy_attach" {
  provider = "aws.us-east-1"

  role       = "${aws_iam_role.cs_logging_server_side_role.name}"
  policy_arn = "${aws_iam_policy.cs_logging_server_side_role_policy.arn}"
}

resource "aws_iam_policy" "cs_logging_server_side_role_policy" {
  provider = "aws.us-east-1"

  name = "cs_logging_server_side_role_policy"

  #aws:userid
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:PutObjectTagging"
      ],
      "Resource": [
        "${aws_s3_bucket.cs_data_bucket.arn}",
        "${aws_s3_bucket.cs_data_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": [
        "arn:aws:s3:::cs-${var.cs_external_id}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource":
        [
          "arn:aws:s3:::cs-${var.cs_external_id}/*"
        ]
    },
    {
      "Action": [
          "kms:GenerateDataKey",
          "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_kms_key.cs_data_bucket_key.arn}"
      ]
    }
  ]
}
EOF
}
