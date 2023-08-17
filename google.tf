# ------------------------------------------------------
# PROVIDER
# ------------------------------------------------------

provider "google" {
  project = var.google_project_id
  region  = "us-east1"
  alias   = "us-east1"
}

module "us-east1" {
  source            = "./deployment/google"
  id                = random_id.stack_id.hex
  region            = "us-east1"
  providers = {
    google = google.us-east1
  }
}

# use this snippet for deployment in another region

# provider "google" {
#   project = var.google_project_id
#   region  = "europe-west1"
#   alias   = "europe-west1"
# }

# module "europe-west1" {
#   source            = "./deployment/google"
#   id                = random_id.stack_id.hex
#   region            = "europe-west1"
#   timeout           = var.timeout
#   runtime           = var.runtime
#   ephemeral_storage = var.ephemeral_storage
#   providers = {
#     google = google.europe-west1
#   }
# }