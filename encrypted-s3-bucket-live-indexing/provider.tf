provider "aws" {
  alias = "us-east-1"

  profile = "personal"
  region  = "us-east-1"

  version = "~> 2.10"
}
