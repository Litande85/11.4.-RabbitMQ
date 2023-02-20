// Create several similar vm 

// Configure the Yandex Cloud provider

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = var.OAuthTocken
  cloud_id  = "b1gob4asoo1qa32tbt9b"
  folder_id = "b1gob4asoo1qa32tbt9b"
  zone      = "ru-central1-a"
}


  
//create vm

resource "yandex_compute_instance" "vm" {
  name = "${var.guest_name_prefix}-vm1${count.index}" #variables.tf 
  count = 2


  resources {
    cores     = 2
    memory    = 2
  
  }

  boot_disk {
    initialize_params {
      image_id = "fd8a67rb91j689dqp60h" #Debian 11
      type     = "network-ssd"
      size     = "16"
    }
  }

  network_interface {
    subnet_id = "e9bf0qhr78eltofkhvbb"
    nat       = true
    ip_address     = "10.128.0.1${count.index}"
    #ip_address     = lookup(var.vm_ips, count.index) #terraform.tfvars
    }

 
  metadata = {
    user-data = "${file("./meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }

  # Copy in the bash script we want to execute.
  # The source is the location of the bash script
  # on the local linux box you are executing terraform
  # from.  The destination is on the new  instance.
  provisioner "file" {
    source      = "/home/user/terraform/checked-versions/RabbitMQ"
    destination = "/home/user/RabbitMQ"
  }  
  
  connection {
    host = "10.128.0.1${count.index}"
    type        = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    port        = 22
    user        = "user"
    agent       = false
    timeout     = "1m"
  }

  # Change name and permissions on bash script and execute from user.

  provisioner "remote-exec" {
    
    inline = [
      "sudo hostnamectl set-hostname ${var.guest_name_prefix}-vm1${count.index}",
      "sudo timedatectl set-timezone Europe/Moscow",
      "sudo sed -i '$a127.0.0.1 ${var.guest_name_prefix}-vm1${count.index}' /etc/hosts",
      "chmod +x /home/user/RabbitMQ/docker.sh",
      "sudo /home/user/RabbitMQ/docker.sh",  # setup docker
      "sudo docker run -d --hostname ${var.guest_name_prefix}-vm1${count.index} --name rabbit-1${count.index} -p 5672:5672 -p 15672:15672 rabbitmq:3-management" # setup RabbitMQ
    ]  
  }
}


