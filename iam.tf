# Configuration du rôle IAM pour les nœuds EC2 du cluster EKS
resource "aws_iam_role" "nodes_general" {
  name = "eks-node-group-general2"

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

# Attachement des politiques IAM pour le rôle des nœuds EKS
resource "aws_iam_policy_attachment" "eks-node-policy" {
  name       = "eks-node-policy"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  roles      = [aws_iam_role.nodes_general.name]
}

resource "aws_iam_policy_attachment" "eks-cni-policy" {
  name       = "eks-cni-policy"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  roles      = [aws_iam_role.nodes_general.name]
}

resource "aws_iam_policy_attachment" "eks-registry-policy" {
  name       = "eks-registry-policy"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  roles      = [aws_iam_role.nodes_general.name]
}

# Configuration du rôle IAM pour le cluster EKS
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster"

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

# Attachement de la politique IAM pour le rôle cluster EKS
resource "aws_iam_policy_attachment" "eks_cluster_policy" {
  name       = "eks_cluster_policy"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  roles      = [aws_iam_role.eks_cluster.name]
}

