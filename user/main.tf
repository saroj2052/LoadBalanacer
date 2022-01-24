resource "aws_iam_user" "user1" {
  name = "user1"
  
}

resource "aws_iam_user" "user2" {
  name = "user2"
  
}

resource "aws_iam_group" "AmazonEC2ContainerRegistryPowerUser" {
  name = "AmazonEC2ContainerRegistryPowerUser"
  
}

resource "aws_iam_group_membership" "team" {
  name = "group_ec2_membership"

  users = [
    aws_iam_user.user1.name,
    aws_iam_user.user2.name,
  ]

  group = aws_iam_group.AmazonEC2ContainerRegistryPowerUser.name
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  
  groups     = [aws_iam_group.AmazonEC2ContainerRegistryPowerUser.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}