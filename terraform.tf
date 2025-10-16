
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"

      # I don't know what versions will work, but 4.x and 5.x are probably OK
      version = ">= 4.0.0, < 6.0.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
