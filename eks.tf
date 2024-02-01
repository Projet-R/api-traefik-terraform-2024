# Création du cluster EKS avec une configuration VPC
resource "aws_eks_cluster" "eks" {
  name     = "fastapi-eks"
  role_arn = aws_iam_role.eks_cluster.arn

  version = "1.29"

  vpc_config {
    endpoint_public_access  = true
    endpoint_private_access = true
    subnet_ids = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id,
    ]
  }
  depends_on = [
    aws_iam_policy_attachment.eks_cluster_policy
  ]
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
  depends_on = [
    aws_iam_policy_attachment.eks-node-policy,
    aws_iam_policy_attachment.eks-cni-policy,
    aws_iam_policy_attachment.eks-registry-policy,
  ]
}
