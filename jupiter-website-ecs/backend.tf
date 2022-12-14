# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket    = "nba67000-cloud-traning-terraform-remote-state"
    key       = "jupiter-website-ecs.tfstate"
    region    = "eu-west-3"
    profile   = "terraform-user"
  }
}