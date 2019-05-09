# Configure the Google Cloud provider
provider "google" {
  credentials = "${file("~/.config/gcloud/application_default_credentials.json")}"
  project     = "${var.google_project}"
  region      = "${var.google_region}"
}

data "google_compute_zones" "available" {}
 
 # Create google network
 resource "google_compute_network" "default" {
   name                    = "miguel-nixos"
   auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "dmz" {
    name          = "dmz"
    ip_cidr_range = "192.168.1.0/24"
    network       = "${google_compute_network.default.self_link}"
    region        = "${var.google_region}"
}

resource "google_compute_subnetwork" "internal" {
    name          = "internal"
    ip_cidr_range = "10.0.1.0/24"
    network       = "${google_compute_network.default.self_link}"
    region        = "${var.google_region}"
}
 
resource "google_compute_firewall" "web" {
    name = "web"
    network = "${google_compute_network.default.name}"
    allow {
        protocol = "tcp"
        ports = ["80"]
    }
}

resource "google_compute_firewall" "ssh" {
    name = "ssh"
    network = "${google_compute_network.default.name}"
    allow {
        protocol = "tcp"
        ports = ["22"]
    }
}

 # deploy image
 resource "google_compute_instance" "vm" {
   name         = "miguel-nixos"
   machine_type = "f1-micro"
   zone         = "${data.google_compute_zones.available.names[1]}"
 
  tags = ["nixos"]

  boot_disk {
    initialize_params {
      image = "gs://nixos-cloud-images/nixos-image-18.09.1228.a4c4cbb613c-x86_64-linux.raw.tar.gz"
    }
  } 
  network_interface {
    subnetwork = "${google_compute_subnetwork.dmz.name}"
    access_config {
        // IP
    }
  } 

  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

   network_interface {
     network = "default"
   }

    service_account {
        scopes = ["https://www.googleapis.com/auth/compute.readonly"]
    }
}
 
resource "null_resource" "nixos-config" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    current_vm_instance_id = "${google_compute_instance.vm.id}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${google_compute_instance.vm.network_interface.0.access_config.0.assigned_nat_ip}"
    user = "${var.gce_ssh_user}"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    content =<<SCRIPT
#!/bin/sh
echo hello world
SCRIPT
destination = "run.sh"
 }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "bash ./run.sh",
    ]
  }
}


#resource "google_dns_managed_zone" "my_managed_zone" {
#  name        = "managed-zone"
#  dns_name    = "${var.top_level_domain}."
#  description = "Production DNS zone"
#}

data "google_dns_managed_zone" "my_managed_zone" {
  name        = "managed-zone"
}

resource "google_dns_record_set" "www" {
    name = "nixos.${var.top_level_domain}."
    type = "A"
    ttl = 300
    managed_zone = "${data.google_dns_managed_zone.my_managed_zone.name}"
    rrdatas = ["${google_compute_instance.vm.network_interface.0.access_config.0.assigned_nat_ip}"]
}
