# Création de la VPC avec un bloc CIDR de 10.0.0.0/16
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Création de la passerelle Internet et l'attachement à la VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Configuration des sous-réseaux privés dans les zones de disponibilité eu-west-3a et eu-west-3b
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-3a"
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-3b"
}

# Configuration des sous-réseaux publics dans les zones de disponibilité eu-west-3a et eu-west-3b
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-3b"
  map_public_ip_on_launch = true
}

#création de la resource table route pour notre VPC
resource "aws_route_table" "vpc_route" {
  vpc_id = aws_vpc.main.id  
}

# Configuration des passerelles NAT pour les sous-réseaux publics
resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.gw]
}

resource "aws_eip" "nat1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.public_2.id
  depends_on    = [aws_internet_gateway.gw]
}

resource "aws_eip" "nat2" {
  domain = "vpc"
}
