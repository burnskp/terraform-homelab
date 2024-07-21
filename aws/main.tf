resource "aws_s3_bucket" "terraform_state" {
  #checkov:skip=CKV2_AWS_61:This holds small files and doesn't need a lifecycle
  #checkov:skip=CKV_AWS_144:This is non-production and doesn't need replicas
  bucket              = "burnskp-dev-tf-state"
  object_lock_enabled = true


  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "terraform_state" {
  description             = "Encryption key for Terraform state bucket"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy = jsonencode({
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}


resource "aws_kms_key" "dnssec" {
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign",
          "kms:Verify",
        ],
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Resource = "*"
        Sid      = "Allow Route 53 DNSSEC Service",
      },
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_route53_zone" "burnskp-dev" {
  name = "burnskp.dev"
}

resource "aws_route53_key_signing_key" "burnskp-dev" {
  hosted_zone_id             = aws_route53_zone.burnskp-dev.id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "burnskp-dev"
}

resource "aws_route53_hosted_zone_dnssec" "burnskp-dev" {
  depends_on = [
    aws_route53_key_signing_key.burnskp-dev
  ]
  hosted_zone_id = aws_route53_key_signing_key.burnskp-dev.hosted_zone_id
}

resource "aws_route53_record" "MX" {
  zone_id = aws_route53_zone.burnskp-dev.zone_id
  name    = "burnskp.dev"
  type    = "MX"
  ttl     = "3600"
  records = ["10 in1-smtp.messagingengine.com", "20 in2-smtp.messagingengine.com"]
}

resource "aws_route53_record" "DKIM" {
  count   = 3
  zone_id = aws_route53_zone.burnskp-dev.zone_id
  name    = "fm${count.index + 1}._domainkey.burnskp.dev"
  type    = "CNAME"
  ttl     = "3600"
  records = ["fm${count.index + 1}.burnskp.dev.dkim.fmhosted.com"]
}

resource "aws_route53_record" "SPF" {
  zone_id = aws_route53_zone.burnskp-dev.zone_id
  name    = "burnskp.dev"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=spf1 include:spf.messagingengine.com ?all"]
}

# Using external DNS for internal IPs is a bit weird, but it saves me from
# having to deal with multiple DNS servers handling the same domain
resource "aws_route53_zone" "lab-burnskp-dev" {
  name = "lab.burnskp.dev"
}

resource "aws_route53_key_signing_key" "lab-burnskp-dev" {
  hosted_zone_id             = aws_route53_zone.lab-burnskp-dev.id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "lab-burnskp-dev"
}

resource "aws_route53_hosted_zone_dnssec" "lab-burnskp-dev" {
  depends_on = [
    aws_route53_key_signing_key.lab-burnskp-dev
  ]
  hosted_zone_id = aws_route53_key_signing_key.lab-burnskp-dev.hosted_zone_id
}

resource "aws_route53_record" "lab-burnskp-dev-NS" {
  zone_id = aws_route53_zone.burnskp-dev.zone_id
  name    = aws_route53_zone.lab-burnskp-dev.name
  type    = "NS"
  ttl     = "3600"
  records = aws_route53_zone.lab-burnskp-dev.name_servers
}

resource "aws_route53_record" "ms01a" {
  zone_id = aws_route53_zone.lab-burnskp-dev.zone_id
  name    = "ms01a.lab.burnskp.dev"
  type    = "A"
  ttl     = "3600"
  records = ["192.168.8.10"]
}

resource "aws_route53_record" "ms01b" {
  zone_id = aws_route53_zone.lab-burnskp-dev.zone_id
  name    = "ms01b.lab.burnskp.dev"
  type    = "A"
  ttl     = "3600"
  records = ["192.168.8.11"]
}

resource "aws_route53_record" "ms01c" {
  zone_id = aws_route53_zone.lab-burnskp-dev.zone_id
  name    = "ms01c.lab.burnskp.dev"
  type    = "A"
  ttl     = "3600"
  records = ["192.168.8.12"]
}

resource "aws_iam_user" "letsencrypt" {
  #checkov:skip=CKV_AWS_273:This is a service account
  name = "letsencrypt-dns01"
  path = "/system/"
}

resource "aws_iam_access_key" "letsencrypt" {
  user = aws_iam_user.letsencrypt.name
}

resource "aws_iam_group" "letsencrypt" {
  name = "letsencrypt"
}

resource "aws_iam_group_policy" "letsencrypt" {
  name  = "letsencrypt-dns01"
  group = aws_iam_group.letsencrypt.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets"]
        Resource = ["arn:aws:route53:::hostedzone/${aws_route53_zone.lab-burnskp-dev.zone_id}"]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:GetChange"]
        Resource = ["arn:aws:route53:::change/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_ses_domain_identity" "lab-burnskp-dev" {
  domain = "lab.burnskp.dev"
}

resource "aws_route53_record" "lab-burnskp-dev-ses" {
  zone_id = aws_route53_zone.lab-burnskp-dev.zone_id
  name    = "_amazonses.lab.burnskp.dev"
  type    = "TXT"
  records = [aws_ses_domain_identity.lab-burnskp-dev.verification_token]
  ttl     = "600"
}
