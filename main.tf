# Configuration du fournisseur AWS dans la région de Paris (eu-west-3)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  backend "remote" {
    organization = "Datasciencetest"

    workspaces {
      name = "api-traefik-kub-2024-DEV"
    }
  }
}
provider "aws" {
  region = "eu-west-3"
}
