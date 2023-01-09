resource "random_id" "node_id" {
  byte_length = 2
  count       = var.main_instance_count
}


data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "n_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "n_main" {
  count                  = var.main_instance_count
  instance_type          = var.main_instance_type
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.n_auth.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.public_subnet[count.index].id
  root_block_device {
    volume_size = var.main_vol_size
  }

  tags = {
    Name = "n-main-${random_id.node_id[count.index].dec}"
  }

  provisioner "local-exec" {
    command = "printf '\n${self.public_ip}' >> aws_hosts && aws ec2 wait instance-status-ok --instance-ids ${self.id} --region us-west-1"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^[0-9]/d' aws_hosts"
  }


}

resource "null_resource" "grafana_install"{
  depends_on = [aws_instance.n_main]
  provisioner "local-exec"{
    command = "ansible-playbook -i aws_hosts --key-file /home/ubuntu/.ssh/nkey playbooks/main-playbook.yml"
  }
}

output "instance_ips" {
  value = { for i in aws_instance.n_main[*] : i.tags.Name => "${i.public_ip}:3000" }
}
