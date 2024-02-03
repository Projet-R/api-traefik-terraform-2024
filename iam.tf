# OIDC config
data "tls_certificate" "certif_eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.certif_eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}


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

resource "aws_iam_policy_attachment" "AWSCertificateManagerRO" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCertificateManagerReadOnly"
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

# Configuration du rôle IAM pour l'addon EBS CSI
resource "aws_iam_role" "eks_ebs_csi" {
  name = "eks_ebs_csi"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::203271543287:oidc-provider/${replace(aws_iam_openid_connect_provider.oidc_eks.url, "https://", "")}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(aws_iam_openid_connect_provider.oidc_eks.url, "https://", "")}:aud": "sts.amazonaws.com",
          "${replace(aws_iam_openid_connect_provider.oidc_eks.url, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
POLICY
}

# Attachement de la politique IAM pour le rôle cluster EBS CSI
resource "aws_iam_policy_attachment" "ebs_csi_controller" {
  name       = "ebs_csi_controller"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  roles      = [aws_iam_role.eks_ebs_csi.name]
}

# Creation du role avec la policy necessaire pour ALB
module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "role_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.oidc_eks.arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# creation du service account pour ALB
resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

