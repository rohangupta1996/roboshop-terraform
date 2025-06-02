resource "aws_instance" "instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = var.vpc_security_group_ids

  tags = {
    Name = var.name
  }
}

resource "aws_route53_record" "record" {
  zone_id = var.zone_id
  name    = "${var.name}-${var.env}"
  type    = "A"
  ttl     = 10
  records = [aws_instance.instance.private_ip]
}

resource "null_resource" "instance" {
  depends_on = [aws_route53_record.record]
  triggers = {
    instance_id_change = aws_instance.instance.id
  }

  provisioner "remote-exec" {

    connection {
      type     = "ssh"
      user     = data.vault_generic_secret.ssh.data["username"]
      password = data.vault_generic_secret.ssh.data["password"]
      host     = aws_instance.instance.private_ip
    }

    inline = [
      "sudo pip3.11 install ansible hvac",
      "ansible pull -i localhost, -U https://github.com/rohangupta1996/roboshop-ansible.git roboshop.yml -e component_name=${var.name} -e env=${var.env} -e vault_token=${var.vault_token}",
    ]
  }
}