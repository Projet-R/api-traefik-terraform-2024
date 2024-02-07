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
    aws_iam_policy_attachment.eks-cluster-policy,
    aws_iam_policy_attachment.eks-clr-acm-ro
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

# Création des namespaces
resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
  }
  depends_on = [
    aws_eks_node_group.nodes_general
  ]
}

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
  }
  depends_on = [
    aws_eks_node_group.nodes_general
  ]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
  depends_on = [
    aws_eks_node_group.nodes_general
  ]
}

# Ajout de l'add-on EBS CSI pour EKS
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.27.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.eks_ebs_csi.arn
  depends_on = [
    aws_iam_policy_attachment.ebs_csi_controller,
    aws_eks_node_group.nodes_general
  ]
}

# Ajout de l'add-on ALB pour EKS via HELM

resource "helm_release" "alb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service-account,
    aws_eks_node_group.nodes_general
  ]
  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.eu-west-3.amazonaws.com/amazon/aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks.name
  }
}
