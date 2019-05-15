# Overview

This configuration will create several objects:
* An SQS queue called sqs-s3-YOUR_BUCKET_NAME-us-east-1
* A bucket called YOUR_BUCKET_NAME-us-east-1
* A bucket notification for YOUR_BUCKET_NAME-us-east-1 that notifies
  sqs-s3-YOUR_BUCKET_NAME-us-east-1 when new files are created
* An IAM role that CHAOSSEARCH can assume to access the bucket and the SQS queue.

## Prerequisites
* An AWS Account
* API keys in your environment with admin privs in the account you want to
  store and index data in. If you haven't already sourced your AWS keys into
  your environment, follow [these instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
* A CHAOSSEARCH Customer ID (you'll get this from your rep, or the first time you log into the console)

# Minimal Usage

```
provider "aws" {
  alias = "us-east-1"
  region  = "us-east-1"
  version = "~> 2.10"
}


module "s3_customer_buckets" {
  source = "git::https://github.com/ChaosSearch/terraform-modules.git//encrypted-s3-bucket-live-indexing"

  region = "us-east-1"
  cs_external_id = "YOUR_EXTERNAL_ID"
  cs_data_bucket = "NAME_FOR_YOUR_NEW_BUCKET"
  sqs_queue = true

  providers = {
    aws = "aws.us-east-1"
  }
}
```


Reach out to your customer support representative for more help.
