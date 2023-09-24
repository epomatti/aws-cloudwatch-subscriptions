module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "prod-sg"
  vpc_id = var.vpc_id

  ingress_rules = ["ssh-tcp"]
  egress_rules  = ["https-443-tcp", "http-80-tcp"]
}

resource "aws_iam_instance_profile" "main" {
  name = "ec2-test-profile"
  role = aws_iam_role.main.arn
}

module "ec2_instance" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  name                        = "prod-instance"
  instance_type               = "t4g.micro"
  user_data                   = file("${path.module}/cloud-init.sh")
  ami                         = "ami-08fdd91d87f63bb09"
  monitoring                  = true
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.sg.security_group_id]
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.main.id
}

resource "aws_iam_role" "main" {
  name = "prod-ec2-role"

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
}

resource "aws_iam_role_policy_attachment" "ssm-managed-instance-core" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatc-agent-server-policy" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
