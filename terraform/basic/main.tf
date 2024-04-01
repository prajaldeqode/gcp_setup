

variable "instanceName" {
  description = "name ofd instance"
}

# Create a VM template
resource "google_compute_instance_template" "vm_template" {
  name                    = "${var.instanceName}-template"
  machine_type            = "n1-standard-1"
  region                  = "us-central1"
  
  disk {
    source_image = "debian-cloud/debian-10"
  }

  network_interface {
    network = "default"
    access_config {
      // Allocate a public IP address
    }
  }
}

# Create an instance group based on the template
resource "google_compute_instance_group_manager" "instance_group" {
  name                = "${var.instanceName}-group"
  base_instance_name = "instance"
  zone                = "us-central1-a"
  version {
    instance_template  = google_compute_instance_template.vm_template.self_link_unique
  }

  named_port {
    name = "http"
    port = 80
  }
}

# Create a health check

resource "google_compute_region_health_check" "region_health_check" {
  name               = "${var.instanceName}-region-health-check"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port = "80"
  }
}

resource "google_compute_region_backend_service" "backend_service" {
  name                    = "${var.instanceName}-backend-service"
  region                  = "us-central1"
  
  backend {
    group = google_compute_instance_group_manager.instance_group.self_link
  }
  
  health_checks           = [google_compute_region_health_check.region_health_check.self_link]
  protocol                = "HTTP"
  timeout_sec             = 10
}

# Create a global forwarding rule to route traffic to the backend service
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "${var.instanceName}-forwarding-rule"
  target                = google_compute_region_backend_service.backend_service.self_link
  port_range            = "80"
}

# Create instances from the template
resource "google_compute_instance_from_template" "my_instances" {
  name          = "${var.instanceName}"
  source_instance_template     = google_compute_instance_template.vm_template.id
}
