# Création de la VPC avec un bloc CIDR de 10.0.0.0/16
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "fastapi-vpc"
  }
}

# Création de la passerelle Internet et attachement au VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "fastapi-internet-gateway"
  }
}

# Configuration des sous-réseaux privés dans les zones de disponibilité eu-west-3a et eu-west-3b
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-3a"
  tags = {
    Name                                = "fastapi-private-1"
    kubernetes.io / role / internal-elb = 1
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-3b"
  tags = {
    Name                                = "fastapi-private-1"
    kubernetes.io / role / internal-elb = 1

  }
}

# Configuration des sous-réseaux publics dans les zones de disponibilité eu-west-3a et eu-west-3b
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true
  tags = {
    Name                       = "fastapi-public-1"
    kubernetes.io / role / elb = 1

  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-3b"
  map_public_ip_on_launch = true
  tags = {
    Name                       = "fastapi-public-2"
    kubernetes.io / role / elb = 1

  }
}

# Creation de la resource de la route table public
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "fastapi-rtb-public"
  }
}

# Ajout de la route par defaut a la route table public
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.public_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Association des sous-reseaux public a la route table public
resource "aws_route_table_association" "rtb_subnet_association_pub_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "rtb_subnet_association_pub_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rtb.id
}

# Configuration des passerelles NAT pour les sous-reseaux prives
resource "aws_eip" "nat_1" {
  domain = "vpc"
}
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id
  tags = {
    Name = "fastapi-nat-public-1"
  }
}

resource "aws_eip" "nat_2" {
  domain = "vpc"
}
resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id
  tags = {
    Name = "fastapi-nat-public-2"
  }
}

# Creer des tables de routage pour les sous-reseaux prives
resource "aws_route_table" "prive_1_rtb" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "fastapi-rtb-prive-1"
  }
}

resource "aws_route_table" "prive_2_rtb" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "fastapi-rtb-prive-2"
  }
}

# Creer des routes vers les passerelles nat
resource "aws_route" "route_priv_1_nat" {
  route_table_id         = aws_route_table.prive_1_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_1.id
}

resource "aws_route" "route_priv_2_nat" {
  route_table_id         = aws_route_table.prive_2_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_2.id
}

# Association des sous-reseaux prives aux route tables privees
resource "aws_route_table_association" "rta_subnet_association_priv_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.prive_1_rtb.id
}
resource "aws_route_table_association" "rta_subnet_association_priv_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.prive_2_rtb.id
}

