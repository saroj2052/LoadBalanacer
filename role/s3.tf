resource "aws_s3_bucket" "sarojshah" {
  bucket = "sarojshah"
  acl    = "private"

  tags = {
    Name        = "saroj-bucket"
  }
}