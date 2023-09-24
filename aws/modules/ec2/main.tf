resource "aws_iam_instance_profile" "main" {
  name = "EC2TestProfile"
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
  vpc_security_group_ids      = [aws_security_group.main.id]
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.main.id
}

### IAM ###

resource "aws_iam_role" "main" {
  name = "ProdEC2Role"

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


### Security Group ###

resource "aws_security_group" "main" {
  name        = "ec2-instance-sg"
  description = "Allow application and management"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-ec2-instance"
  }
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}
