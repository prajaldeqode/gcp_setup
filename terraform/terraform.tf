provider "google" {
  project     = "alfred-rc1-a2df"
  region      = "us-central1"
  # zone    = "us-central1-c"
}

variable instanceName {
  type        = list(string)
  default     = ["t-express","t-mongodb","t-prometheus"]
  description = "instance Name"
}


resource "google_compute_instance" "vm_instance" {
  count = length(var.instanceName)
  name         = "${var.instanceName[count.index]}"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "default"
    access_config {
    }
  }
}

#health check
resource "google_compute_http_health_check" "http_health_check" {
  name               = "http-health-check"
  request_path       = "/"
  port               = 80
  check_interval_sec = 5
  timeout_sec        = 5
}

# Create instance group
resource "google_compute_instance_group" "vm_instance_group" {
  name        = "vm-instance-group"
  description = "Instance group for VM instances"
  zone        = "us-central1-a"

  named_port {
    name = "http"
    port = 80
  }
}

# Create backend service
resource "google_compute_backend_service" "backend_service" {
  name       = "backend-service"
  port_name  = "http"
  protocol   = "HTTP"
  backend {
    group = google_compute_instance_group.vm_instance_group.self_link
  }
  health_checks = [google_compute_http_health_check.http_health_check.self_link]
}

# Create global forwarding rule
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = "forwarding-rule"
  port_range = "80"
  target     = google_compute_backend_service.backend_service.self_link
}

# Create global IP address
resource "google_compute_global_address" "lb_ip" {
  name          = "lb-ip"
  purpose       = "GCE_ENDPOINT"
  address_type  = "EXTERNAL"
}

# Create DNS record
resource "google_dns_record_set" "lb_dns" {
  name          = "lb-dns.example.com."
  type          = "A"
  ttl           = 300
  managed_zone  = "example-zone"
  rrdatas       = [google_compute_global_address.lb_ip.address]
}