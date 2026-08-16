# ⚠️ INTENTIONALLY INSECURE — demo only.
# This file exists on a throwaway branch to prove the CI security gate blocks bad code.
# It is NEVER merged to main. Checkov flags this SG for allowing SSH (22) from the whole internet.

resource "aws_security_group" "insecure_demo" {
  name        = "insecure-demo"
  description = "Intentionally insecure SG for the blocked-PR demo"
  vpc_id      = "vpc-00000000000000000"

  ingress {
    description = "SSH open to the entire internet — this is the bad rule Checkov should block"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
