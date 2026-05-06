provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "k8s_sg" {
  name = "k8s-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_server" {
  ami           = "ami-03f4878755434977f"
  instance_type = "t2.micro"
  key_name      = "devopskey"

  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt update -y

              apt install -y docker.io
              systemctl start docker
              systemctl enable docker

              apt install -y apt-transport-https curl
              curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

              echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list

              apt update
              apt install -y kubelet kubeadm kubectl

              kubeadm init --pod-network-cidr=10.244.0.0/16

              mkdir -p /home/ubuntu/.kube
              cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
              chown ubuntu:ubuntu /home/ubuntu/.kube/config

              su - ubuntu -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
              EOF

  tags = {
    Name = "K8s-FreeTier"
  }
}

output "public_ip" {
  value = aws_instance.k8s_server.public_ip
}