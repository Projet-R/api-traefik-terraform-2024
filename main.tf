# Configuration du fournisseur AWS dans la région de Paris (eu-west-3)
provider "aws" {
  region = "eu-west-3" # Région de Paris
}

terraform {
  backend "remote" {
    organization = "Datasciencetest"

    workspaces {
        name = "api-traefik-kub-2024-DEV"
      
    }
    
  }
}