provider "google" {
  project = var.project
  region  = var.region
}
data "google_client_config" "current" {}

// Create a network for Compute
resource "google_compute_network" "network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

// Create subnets
resource "google_compute_subnetwork" "subnetwork" {
  name                     = var.subnetwork_name
  network                  = google_compute_network.network.self_link
  ip_cidr_range            = var.subnetwork_range
  private_ip_google_access = true
}

resource "google_compute_firewall" "ssh-iap" {
  name = "allow-ssh-iap"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.network.name
  priority      = 1000
  source_ranges = [var.ssh_iap_range]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "ssh-cloudadmin" {
  name = "allow-ssh-cloudadmin"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.network.name
  priority      = 1000
  source_ranges = ["189.210.45.178/32", "34.69.164.46/32"]
  target_tags   = ["ssh"]
}

// The user-data script on Runner instance provisioning
data "template_file" "startup_script" {
  template = <<-EOF
  sudo useradd -m -c "Ansible deployer" -s /bin/bash ansible
  echo "# User rules for ansible" | sudo tee /etc/sudoers.d/99_ansible
  echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/99_ansible
  sudo mkdir /home/ansible/.ssh
  sudo chmod 700 /home/ansible/.ssh
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDf7vxFoSu/p863jXiUPWfVtuM+WNEWJQQnB6XND3+SMdfzUGG3aPSFEWMpd4W30230DWJ9cCdIrVEbR1vSgFAsuwvHrrKtkUOGOKkByhg86Kw1Q4jUzLMHfV3tI01N9rGswEvpaN4ShLZ6ImEhuQOnBYniLMcxthhcqcWFV1P+iML7kJGAhQYTqa/U67wz+eKoaX6uOWhkX4KnvMeFbXpq3zyr8CYhs6wiWPdf2iAkvDR5rceRfdbt+gZCH+lAPvN4CYt0RiKYrTX6EfkndpuBbvsxk9yzEcvjaGptlUHQb69//2eShsC3rVtjghm+kD9ESpPmgVEj/HphRgim0FPjPrKxXvbIIBkyf8960aLMBMPUSF0dH/TOhrM97rJ14W8vSX3bwjLUq9YvsDArVZAhk041GLIO7yePlfWa+eFD16r6KNuYl5APmBatEPXuG9NrOTi6RU1lL42rB8MaV9M6NC6eg46TmDZY9emU0JDVG7xGnz8ACnPTYEZgDzji+IQFJhwYUt3vNE+qBS5d2dHLvm1rtzDTs9UQwDu6hlHti4jO+a/KqQwp+NBRYEP6sqku0HTQH6ZM4iQMUN1RKvxzczqS56vVnnl86AN7+p3rpizplLhGUvnJhSh3ZnsLA96aa5KmTxOa2snbMrC22GreMyIklDMHigxZEjwLQ69whQ== ansible@resuelve" | sudo tee -a /home/ansible/.ssh/authorized_keys
  sudo chmod 600 /home/ansible/.ssh/authorized_keys
  sudo chown -R ansible:ansible /home/ansible/.ssh
  sudo apt-get update -y -qq
  sudo apt-get install unzip -y
  sudo apt-get install make -y
  sudo apt-get install erlang-dev -y
  sudo apt-get install build-essential -y
  sudo apt-get install python3 python3-pip -y
  sudo snap install yq
  curl -fsSL https://get.docker.com -o get-docker.sh
  DRY_RUN=1 sudo sh ./get-docker.sh
  sudo usermod -a -G docker ansible
  export DOCKER_CLI_EXPERIMENTAL=enabled
  KUBECTL_VERSION=$(curl -L -s "https://dl.k8s.io/release/stable.txt")
  sudo curl -s -o /usr/local/bin/kubectl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
  sudo chmod 755 /usr/local/bin/kubectl
  sudo curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
  EOF

}

# Create a single Compute Engine instance
resource "google_compute_instance" "default" {
  count        = "2"
  name         = "${var.vm_name_prefix}${count.index + 1}"
  machine_type = var.vm_machine_type
  zone         = var.zone
  tags         = ["ssh"]

  labels = {
    "linea-negocio" = "${var.label_business}"
    "proyecto"      = "${var.label_project}"
    "environment"   = "${var.label_environment}"
    "product-owner" = "${var.label_owner}"
    "datadog"       = "${var.label_datadog}"
    "gh_actions"    = "${var.label_gh_actions}"
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
  boot_disk {
    initialize_params {
      image = var.image_os
      type  = var.disk_type
      size  = var.disk_size
    }

  }

  // Ensure that when the gh-runner host is booted all dependencies are installed
  metadata_startup_script = data.template_file.startup_script.rendered

  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.name

    access_config {
      # Include this section to give the VM an external IP address
    }
  }
}
