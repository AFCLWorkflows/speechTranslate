# ------------------------------------------------------
# MODULE INPUT
# ------------------------------------------------------

variable id {}
variable region {}

# ------------------------------------------------------
# UPLOAD DEPLOYMENT PACKAGES
# ------------------------------------------------------

resource "google_storage_bucket" "deployment_bucket" {
  name          = "deployment-packages-${var.region}-${var.id}"
  location      = var.region
  force_destroy = true
}

data "archive_file" "collect_deployment_package" {
  type        = "zip"
  source_file = "${path.root}/collect/target/deployable/collect-1.0-SNAPSHOT.jar"
  output_path = "${path.root}/collect/target/deployable/collect-1.0-SNAPSHOT.zip"
}

data "archive_file" "transcribe_deployment_package" {
  type        = "zip"
  source_file = "${path.root}/transcribe/target/deployable/transcribe-1.0-SNAPSHOT.jar"
  output_path = "${path.root}/transcribe/target/deployable/transcribe-1.0-SNAPSHOT.zip"
}

data "archive_file" "translate_deployment_package" {
  type        = "zip"
  source_file = "${path.root}/translate/target/deployable/translate-1.0-SNAPSHOT.jar"
  output_path = "${path.root}/translate/target/deployable/translate-1.0-SNAPSHOT.zip"
}

data "archive_file" "synthesize_deployment_package" {
  type        = "zip"
  source_file = "${path.root}/synthesize/target/deployable/synthesize-1.0-SNAPSHOT.jar"
  output_path = "${path.root}/synthesize/target/deployable/synthesize-1.0-SNAPSHOT.zip"
}

data "archive_file" "merge_deployment_package" {
  type        = "zip"
  source_file = "${path.root}/merge/target/deployable/merge-1.0-SNAPSHOT.jar"
  output_path = "${path.root}/merge/target/deployable/merge-1.0-SNAPSHOT.zip"
}

resource "google_storage_bucket_object" "collect_bucket_object" {
  name   = "collect.zip"
  bucket = google_storage_bucket.deployment_bucket.name
  source = data.archive_file.collect_deployment_package.output_path
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

resource "google_storage_bucket_object" "transcribe_bucket_object" {
  name   = "extract.zip"
  bucket = google_storage_bucket.deployment_bucket.name
  source = data.archive_file.transcribe_deployment_package.output_path
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

resource "google_storage_bucket_object" "translate_bucket_object" {
  name   = "translate.zip"
  bucket = google_storage_bucket.deployment_bucket.name
  source = data.archive_file.translate_deployment_package.output_path
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

resource "google_storage_bucket_object" "synthesize_bucket_object" {
  name   = "synthesize.zip"
  bucket = google_storage_bucket.deployment_bucket.name
  source = data.archive_file.synthesize_deployment_package.output_path
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

resource "google_storage_bucket_object" "merge_bucket_object" {
  name   = "merge.zip"
  bucket = google_storage_bucket.deployment_bucket.name
  source = data.archive_file.merge_deployment_package.output_path
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

# ------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------

resource "google_cloudfunctions_function" "collect_function" {
  name                  = "collect"
  runtime               = "java11"
  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.deployment_bucket.name
  source_archive_object = google_storage_bucket_object.collect_bucket_object.name
  trigger_http          = true
  entry_point           = "function.CollectFunction"
  timeout               = 500
}

resource "google_cloudfunctions_function" "transcribe_function" {
  name                  = "transcribe"
  runtime               = "java11"
  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.deployment_bucket.name
  source_archive_object = google_storage_bucket_object.transcribe_bucket_object.name
  trigger_http          = true
  entry_point           = "function.TranscribeFunction"
  timeout               = 500
}

resource "google_cloudfunctions_function" "translate_function" {
  name                  = "translate"
  runtime               = "java11"
  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.deployment_bucket.name
  source_archive_object = google_storage_bucket_object.translate_bucket_object.name
  trigger_http          = true
  entry_point           = "function.TranslateFunction"
  timeout               = 500
}

resource "google_cloudfunctions_function" "synthesize_function" {
  name                  = "synthesize"
  runtime               = "java11"
  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.deployment_bucket.name
  source_archive_object = google_storage_bucket_object.synthesize_bucket_object.name
  trigger_http          = true
  entry_point           = "function.SynthesizeFunction"
  timeout               = 500
}

resource "google_cloudfunctions_function" "merge_function" {
  name                  = "merge"
  runtime               = "java11"
  available_memory_mb   = 8192
  source_archive_bucket = google_storage_bucket.deployment_bucket.name
  source_archive_object = google_storage_bucket_object.merge_bucket_object.name
  trigger_http          = true
  entry_point           = "function.MergeFunction"
  timeout               = 500
}

# ------------------------------------------------------
# IAM
# ------------------------------------------------------

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "collect_invoker" {
  project        = google_cloudfunctions_function.collect_function.project
  region         = google_cloudfunctions_function.collect_function.region
  cloud_function = google_cloudfunctions_function.collect_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "transcribe_invoker" {
  project        = google_cloudfunctions_function.translate_function.project
  region         = google_cloudfunctions_function.translate_function.region
  cloud_function = google_cloudfunctions_function.translate_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "translate_invoker" {
  project        = google_cloudfunctions_function.translate_function.project
  region         = google_cloudfunctions_function.translate_function.region
  cloud_function = google_cloudfunctions_function.translate_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "synthesize_invoker" {
  project        = google_cloudfunctions_function.synthesize_function.project
  region         = google_cloudfunctions_function.synthesize_function.region
  cloud_function = google_cloudfunctions_function.synthesize_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "merge_invoker" {
  project        = google_cloudfunctions_function.merge_function.project
  region         = google_cloudfunctions_function.merge_function.region
  cloud_function = google_cloudfunctions_function.merge_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
