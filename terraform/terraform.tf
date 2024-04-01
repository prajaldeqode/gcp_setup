provider "google" {
  alias = "google101"
  credentials = file("./alfred-rc1-a2df-3b8722980b7e.json")
  project = "alfred-rc1-a2df"
  region  = "us-central1"
  zone    = "us-central1-c"
}

variable "instanceName" {
  type        = list(string)
  default     = ["t-express", "t-mongodb", "t-prometheus"]
  description = "instance Name"
}

module "base" {
  count = 3
  source = "./basic"
  providers = {
    google = google.google101
  }
  instanceName = var.instanceName[count.index]
}