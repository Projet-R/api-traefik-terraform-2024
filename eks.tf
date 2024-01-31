# Création du cluster EKS avec une configuration VPC
resource "aws_eks_cluster" "eks" {
  name     = "fastapi-eks"
  role_arn = aws_iam_role.eks_cluster.arn

  version = "1.27"

  vpc_config {
    endpoint_public_access  = true
    endpoint_private_access = false
    subnet_ids = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id,
    ]
  }
}

# Groupes de sécurité pour les nœuds EKS
resource "aws_security_group" "eks_nodes_sg" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Configuration du groupe de nœuds EC2 pour le cluster EKS
resource "aws_eks_node_group" "nodes_general" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "nodes-general"
  node_role_arn   = aws_iam_role.nodes_general.arn
  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }
  ami_type             = "AL2_x86_64"
  capacity_type        = "ON_DEMAND"
  disk_size            = 20
  force_update_version = false
  instance_types       = ["t3.medium"]
  labels = {
    role = "nodes-general"
  }
}