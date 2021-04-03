data "google_compute_image" "ubuntu2004" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_storage_bucket" "valheim" {
  name          = format("valheim-%s", lower(var.world_name)) # Could also use account ID?
  force_destroy = true
  location      = upper(var.region)
  provisioner "local-exec" {
    command = <<EOT
    cd objects/worlds
    zip -r ../worlds.zip .
    EOT
  }
}

resource "google_storage_bucket_object" "compose" {
  name   = "docker-compose.yml"
  source = "objects/docker-compose.yml"
  bucket = google_storage_bucket.valheim.name
}

resource "google_storage_bucket_object" "worlds" {
  name   = "worlds.zip"
  source = "objects/worlds.zip"
  bucket = google_storage_bucket.valheim.name
}

resource "google_compute_instance" "valheim" {
  depends_on = [
    google_storage_bucket_object.worlds,
    google_storage_bucket_object.compose
  ]
  name         = "valheim"
  machine_type = "e2-medium" # 2 vCPUs, 4G RAM
  zone         = format("%s-a", var.region)
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu2004.self_link
    }
  }

  allow_stopping_for_update = true

  service_account {
    scopes = [ "storage-rw" ] # TODO refine further
  }

  network_interface {
    network = "default"

    access_config {
      network_tier = "STANDARD"
    }
  }

  metadata_startup_script = <<EOT
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo apt -y install docker-compose unzip
  gsutil cp gs://${google_storage_bucket.valheim.name}/docker-compose.yml .
  gsutil cp gs://${google_storage_bucket.valheim.name}/worlds.zip .
  mkdir -p ./valheim/saves/worlds
  unzip worlds.zip -d ./valheim/saves/worlds/
  chown -R ubuntu:ubuntu ./valheim
  sed -i 's/SERVERNAME/${var.server_name}/g' docker-compose.yml
  sed -i 's/WORLDNAME/${var.world_name}/g' docker-compose.yml
  sed -i 's/SERVERPASSWORD/${var.server_password}/g' docker-compose.yml
  docker-compose up -d
  (crontab -l 2>/dev/null; echo "*/5 * * * * /snap/bin/gsutil cp /valheim/saves/worlds/* gs://${google_storage_bucket.valheim.name}/backup-worlds/") | crontab -
  EOT

  # Apply the firewall rule to allow external IPs to access this instance
  tags = ["valheim-server"]
}

resource "google_compute_firewall" "valheim" {
  name    = "default-valheim"
  network = "default"

  allow {
    protocol = "udp"
    ports    = ["2456-2458"]
  }

  # Allow traffic from everywhere to instances with an valheim-server tag to valheim ports
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["valheim-server"]
}

resource "google_compute_firewall" "ssh" {
  name    = "default-valheim-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Allow traffic from specified range to instances with an valheim-server tag to ssh
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["valheim-server"]
}

# so I can use my domain in route53. default false
data "aws_route53_zone" "my_hosted_zone" {
  count        = var.use_route53 ? 1 : 0
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_record" "valheim" {
  count           = var.use_route53 ? 1 : 0
  zone_id         = data.aws_route53_zone.my_hosted_zone.0.id
  name            = format("valheim.%s", data.aws_route53_zone.my_hosted_zone.0.name)
  type            = "A"
  ttl             = 60
  records         = [google_compute_instance.valheim.network_interface.0.access_config.0.nat_ip]
  allow_overwrite = true
}