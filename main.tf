resource "aws_iam_role" "nodes_general" {

  name = "eks-node-group-general"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }, 
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Resource: aws_iam_role_policy_attachment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy_general" {
  # The ARN of the policy you want to apply.
  # https://github.com/SummitRoute/aws_managed_policies/blob/master/policies/AmazonEKSWorkerNodePolicy
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

  # The role the policy should be applied to
  role = aws_iam_role.nodes_general.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy_general" {
  # The ARN of the policy you want to apply.
  # https://github.com/SummitRoute/aws_managed_policies/blob/master/policies/AmazonEKS_CNI_Policy
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

  # The role the policy should be applied to
  role = aws_iam_role.nodes_general.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  # The ARN of the policy you want to apply.
  # https://github.com/SummitRoute/aws_managed_policies/blob/master/policies/AmazonEC2ContainerRegistryReadOnly
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

  # The role the policy should be applied to
  role = aws_iam_role.nodes_general.name
}


# Resource: aws_eks_node_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group

resource "aws_eks_node_group" "nodes_general" {
  # Name of the EKS Cluster.
  cluster_name = aws_eks_cluster.eks.name

  # Name of the EKS Node Group.
  node_group_name = "nodes-general"

  # Amazon Resource Name (ARN) of the IAM Role that provides permissions for the EKS Node Group.
  node_role_arn = aws_iam_role.nodes_general.arn

  # Identifiers of EC2 Subnets to associate with the EKS Node Group. 
  # These subnets must have the following resource tag: kubernetes.io/cluster/CLUSTER_NAME 
  # (where CLUSTER_NAME is replaced with the name of the EKS Cluster).
  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  # Configuration block with scaling settings
  scaling_config {
    # Desired number of worker nodes.
    desired_size = 2

    # Maximum number of worker nodes.
    max_size = 2

    # Minimum number of worker nodes.
    min_size = 1
  }

  # Type of Amazon Machine Image (AMI) associated with the EKS Node Group.
  # Valid values: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64
  ami_type = "AL2_x86_64"

  # Type of capacity associated with the EKS Node Group. 
  # Valid values: ON_DEMAND, SPOT
  capacity_type = "ON_DEMAND"

  # Disk size in GiB for worker nodes
  disk_size = 20

  # Force version update if existing pods are unable to be drained due to a pod disruption budget issue.
  force_update_version = false

  # List of instance types associated with the EKS Node Group
  instance_types = ["t3.medium"]

  labels = {
    role = "nodes-general"
  }

  # Kubernetes version
  version = "1.27"

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy_general,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy_general,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]
}



resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster"

  # create role iam

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# attach the policy to the role


resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  role = aws_iam_role.eks_cluster.name

}


resource "aws_eks_cluster" "eks" {

  name = "eks"

  role_arn = aws_iam_role.eks_cluster.arn

  version = "1.27"

  vpc_config {

    endpoint_public_access = true

    endpoint_private_access = false

    subnet_ids = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id,
      aws_subnet.public_1.id,
      aws_subnet.public_2.id

    ]

  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy
  ]



}
resource "aws_eip" "nat1" {
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "main"
  }

}

resource "aws_eip" "nat2" {
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main"
  }
}

resource "aws_nat_gateway" "gw1" {
  allocation_id = aws_eip.nat1.id
  subnet_id = aws_subnet.public_1.id
  tags = {
    Name = "NAT 1"
  }
}


resource "aws_nat_gateway" "gw2" {
  allocation_id = aws_eip.nat2.id

  subnet_id = aws_subnet.public_2.id

  tags = {
    Name = "NAT 2"
  }

}

provider "aws" {
  profile = "default"
  region  = "eu-west-3"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.21"
    }

  }
}
resource "aws_route_table_association" "public1" {

  subnet_id = aws_subnet.public_1.id

  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {

  subnet_id = aws_subnet.public_2.id

  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {

  subnet_id = aws_subnet.private_1.id

  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private2" {

  subnet_id = aws_subnet.private_2.id

  route_table_id = aws_route_table.private_2.id
}
resource "aws_route_table" "public" {

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public"
  }

}


resource "aws_route_table" "private_1" {

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = aws_nat_gateway.gw1.id
  }

  tags = {
    Name = "private1"
  }

}

resource "aws_route_table" "private_2" {

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = aws_nat_gateway.gw2.id
  }

  tags = {
    Name = "private2"
  }

}
resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.0.0/18"

  availability_zone = "eu-west-3a"

  map_public_ip_on_launch = true

  tags = {
    Name                        = "public-eu-west-3a"
    "kubernetes.io/cluster/eks" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.64.0/18"

  availability_zone = "eu-west-3b"

  map_public_ip_on_launch = true

  tags = {
    Name                        = "public-eu-west-3b"
    "kubernetes.io/cluster/eks" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.128.0/18"

  availability_zone = "eu-west-3a"

  map_public_ip_on_launch = true

  tags = {
    Name                              = "private-eu-west-3a"
    "kubernetes.io/cluster/eks"       = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.192.0/18"

  availability_zone = "eu-west-3b"

  map_public_ip_on_launch = true

  tags = {
    Name                              = "private-eu-west-3b"
    "kubernetes.io/cluster/eks"       = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_db_instance" "rds_instance_1" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"  # Remplacez par votre moteur de base de données
  engine_version       = "5.7"    # Remplacez par votre version de moteur
  instance_class       = "db.t2.micro"  # Remplacez par le type d'instance RDS souhaité
  name                 = "mydb1"  # Nom de votre instance RDS
  username             = "dbuser" # Nom d'utilisateur de la base de données
  password             = "dbpassword"  # Mot de passe de la base de données
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  multi_az             = false  # Désactivez la réplication multi-AZ si nécessaire
  skip_final_snapshot  = true   # Pour éviter la création d'un snapshot final lors de la suppression de l'instance (si nécessaire)

  # D'autres paramètres personnalisables selon vos besoins
}

resource "aws_db_instance" "rds_instance_2" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb2"
  username             = "dbuser"
  password             = "dbpassword"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  multi_az             = false
  skip_final_snapshot  = true

  # D'autres paramètres personnalisables selon vos besoins
}


resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"

  instance_tenancy = "default"

  enable_dns_support = true

  enable_dns_hostnames = true

  #enable_classisclink_dns_suport = false

  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = "main"
  }
}


output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC id"
  sensitive   = false
}

