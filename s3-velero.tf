provider "aws" {
  region = "eu-west-3"
}

resource "aws_s3_bucket" "backup" {
  bucket = "backup-velero"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_acl" "backup" {
  bucket = aws_s3_bucket.backup.id

  acl = "private"
}

data "aws_iam_policy_document" "backup_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts"]
    resources = ["${aws_s3_bucket.backup.arn}/*"]
    effect    = "Allow"
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.backup.arn]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "backup_policy" {
  count        = length(aws_s3_bucket.backup) == 1 ? 1 : 0
  name         = "backup-velero-policy"
  description  = "Policy for Velero backup bucket"
  policy       = data.aws_iam_policy_document.backup_policy.json
}

resource "aws_s3_bucket_policy" "backup_bucket_policy" {
  count  = length(aws_s3_bucket.backup) == 1 ? 1 : 0
  bucket = aws_s3_bucket.backup[count.index].id
  policy = aws_iam_policy.backup_policy[count.index].arn
}
