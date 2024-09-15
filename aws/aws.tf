# AWS - Required resources to deploy the Control Plane Agent

variable "agent_instance_type" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "user_data" {
  type      = string
  sensitive = true
}

variable "security_group_id" {
  type = string
}

variable "create_security_group" {
  type    = bool
  default = true
}

resource "aws_security_group" "allow_outbound_only" {

  count = var.create_security_group ? 1 : 0

  name   = "cpln_agent_allow_outbound_only"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "aws_ami" "cpln_latest_agent" {
  most_recent = true

  filter {
    name   = "name"
    values = ["controlplane-agent-*"]
  }

  owners = ["958621391921"]
}

resource "aws_instance" "cpln_aws_agent" {

  ami           = data.aws_ami.cpln_latest_agent.id
  instance_type = var.agent_instance_type

  subnet_id = var.subnet_id

  vpc_security_group_ids = var.create_security_group ? [aws_security_group.allow_outbound_only[0].id] : [var.security_group_id]

  # The associate_public_ip_address must be set to true if the associated subnet does not have a network gateway.
  associate_public_ip_address = true

  user_data = var.user_data

  root_block_device {
    volume_size           = 15
    volume_type           = "gp2"
    delete_on_termination = true
    encrypted             = true
  }
}

output "security_group_id" {
  value = var.create_security_group ? aws_security_group.allow_outbound_only[0].id : var.security_group_id
}
