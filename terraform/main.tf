provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "prometheus" {
  ami           = "ami-0f96c63e39f9144bc"
  instance_type = "t2.micro"
  key_name      = "MyKeyPair"

  tags = {
    Name = "Prometheus"
  }

   user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y wget tar
              cd /opt
              wget https://github.com/prometheus/prometheus/releases/download/v2.37.9/prometheus-2.37.9.linux-amd64.tar.gz
              tar xvf prometheus-2.37.9.linux-amd64.tar.gz
              cd prometheus-2.37.9.linux-amd64
              cat <<EOT >> prometheus.yml
              global:
                scrape_interval: 15s
              scrape_configs:
                - job_name: 'prometheus'
                  static_configs:
                    - targets: ['localhost:9090']
              EOT
              ./prometheus --config.file=prometheus.yml &
              EOF
}

resource "aws_instance" "grafana" {
  ami           = "ami-0f96c63e39f9144bc"
  instance_type = "t2.micro"
  key_name      = "MyKeyPair"

  tags = {
    Name = "Grafana"
  }

   user_data = <<-EOF
              #!/bin/bash
              yum update -y
              cat <<EOT >> /etc/yum.repos.d/grafana.repo
              [grafana]
              name=grafana
              baseurl=https://packages.grafana.com/oss/rpm
              repo_gpgcheck=1
              enabled=1
              gpgcheck=1
              gpgkey=https://packages.grafana.com/gpg.key
              EOT
              yum install -y grafana
              systemctl enable grafana-server
              systemctl start grafana-server
              EOF
}

resource "aws_security_group" "prometheus_grafana" {
  name        = "prometheus_grafana_sg"
  description = "Allow Prometheus and Grafana traffic"

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["192.168.5.72/32"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["192.168.5.72/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.5.72/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "prometheus_public_ip" {
  value = aws_instance.prometheus.public_ip
}

output "grafana_public_ip" {
  value = aws_instance.grafana.public_ip
}
