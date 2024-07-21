output "letsencrypt_key_id" {
  value     = aws_iam_access_key.letsencrypt.id
  sensitive = true
}

output "letsencrypt_key_secret" {
  value     = aws_iam_access_key.letsencrypt.secret
  sensitive = true
}
