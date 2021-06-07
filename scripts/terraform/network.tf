resource "aws_default_vpc" "default" {
}

resource "aws_default_subnet" "a" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "b" {
  availability_zone = "us-east-1b"
}

resource "aws_default_subnet" "c" {
  availability_zone = "us-east-1c"
}

resource "aws_default_subnet" "d" {
  availability_zone = "us-east-1d"
}

resource "aws_default_subnet" "e" {
  availability_zone = "us-east-1e"
}

resource "aws_default_subnet" "f" {
  availability_zone = "us-east-1f"
}

resource "aws_security_group" "webservers" {
  name = "webservers"
  vpc_id = aws_default_vpc.default.id

  ingress {
    description = "plain text"
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "webbackends" {
  name = "webbackends"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port = 0
    protocol = -1
    to_port = 0
    security_groups = [
      aws_security_group.webservers.id
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 2.78.0"

  name = "otel-playground-vpc"
  cidr = "10.0.0.0/16"

  azs = [
    "us-east-1c",
    "us-east-1d",
    "us-east-1f"
  ]
  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]

  enable_ipv6 = true

  enable_dns_support = true
  enable_dns_hostnames = true

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_sts_endpoint = true
  sts_endpoint_security_group_ids = [
    data.aws_security_group.default.id
  ]

  public_subnet_tags = {
    "kubernetes.io/cluster/opentelemetry-playground": "shared"
    "kubernetes.io/role/elb": "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/opentelemetry-playground": "shared"
    "kubernetes.io/role/internal-elb": "1"
  }
}

data "aws_nat_gateway" "vpc" {
  id = module.vpc.natgw_ids[0]
}
