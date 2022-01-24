resource "aws_iam_role" "s3_bucket_role" {
  name = "s3_bucket_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "s3_bucket_role"
  }
}

# attach iam role policy [aws_iam_role_policy]
resource "aws_iam_role_policy" "s3_bucket_role_policy" {
  name = "s3_bucket_role_policy"
  role = aws_iam_role.s3_bucket_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::sarojshah", "arn:aws:s3:::sarojshah/*"]
      },
    ]
  })
}

# Instance identifier 


resource "aws_iam_instance_profile" "s3-iam-role-instance-profile" {
  name = "s3-iam-role-instance-profile"
  role = aws_iam_role.s3_bucket_role.name
}