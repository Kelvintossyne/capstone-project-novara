terraform {
  backend "s3" {
    bucket         = "novara-tfstate-745914010393"
    key            = "capstone/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
