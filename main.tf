# Configuration du fournisseur AWS dans la région de Paris (eu-west-3)
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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