# ------------------------------------------------------
# MODULE INPUT
# ------------------------------------------------------

variable id {}
variable region {}

# ------------------------------------------------------
# UPLOAD DEPLOYMENT PACKAGES
# ------------------------------------------------------

# Create a bucket
resource "aws_s3_bucket" "deployment_bucket" {
  bucket        = "deployment-packages-${var.region}-${var.id}"
  force_destroy = true
}

# Create access control list for bucket
# resource "aws_s3_bucket_acl" "deployment_bucket_acl" {
#   bucket   = aws_s3_bucket.deployment_bucket.id
#   acl      = "private"
# }

# Upload deployment package for collect function
resource "aws_s3_object" "collect_deployment_package" {
  bucket = aws_s3_bucket.deployment_bucket.id
  key    = "collect.jar"
  acl    = "private"  # or can be "public-read"
  source = "${path.root}/collect/target/deployable/collect-1.0-SNAPSHOT.jar"
  etag   = filemd5("${path.root}/collect/target/deployable/collect-1.0-SNAPSHOT.jar")
}

# Upload deployment package for transcribe function
resource "aws_s3_object" "transcribe_deployment_package" {
  bucket = aws_s3_bucket.deployment_bucket.id
  key    = "transcribe.jar"
  acl    = "private"  # or can be "public-read"
  source = "${path.root}/transcribe/target/deployable/transcribe-1.0-SNAPSHOT.jar"
  etag   = filemd5("${path.root}/transcribe/target/deployable/transcribe-1.0-SNAPSHOT.jar")
}

# Upload deployment package for translate function
resource "aws_s3_object" "translate_deployment_package" {
  bucket = aws_s3_bucket.deployment_bucket.id
  key    = "translate.jar"
  acl    = "private"  # or can be "public-read"
  source = "${path.root}/translate/target/deployable/translate-1.0-SNAPSHOT.jar"
  etag   = filemd5("${path.root}/translate/target/deployable/translate-1.0-SNAPSHOT.jar")
}

# Upload deployment package for synthesize function
resource "aws_s3_object" "synthesize_deployment_package" {
  bucket = aws_s3_bucket.deployment_bucket.id
  key    = "synthesize.jar"
  acl    = "private"  # or can be "public-read"
  source = "${path.root}/synthesize/target/deployable/synthesize-1.0-SNAPSHOT.jar"
  etag   = filemd5("${path.root}/synthesize/target/deployable/synthesize-1.0-SNAPSHOT.jar")
}

# Upload deployment package for merge function
resource "aws_s3_object" "merge_deployment_package" {
  bucket = aws_s3_bucket.deployment_bucket.id
  key    = "merge.jar"
  acl    = "private"  # or can be "public-read"
  source = "${path.root}/merge/target/deployable/merge-1.0-SNAPSHOT.jar"
  etag   = filemd5("${path.root}/merge/target/deployable/merge-1.0-SNAPSHOT.jar")
}

# ------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------

# collect function
resource "aws_lambda_function" "collect_function" {
  function_name    = "collect"
  s3_bucket        = aws_s3_object.collect_deployment_package.bucket
  s3_key           = aws_s3_object.collect_deployment_package.key
  runtime          = "java11"
  handler          = "function.CollectFunction::handleRequest"
  source_code_hash = filebase64sha256(aws_s3_object.collect_deployment_package.source)
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 500
  memory_size      = 512
  ephemeral_storage { size = 512 }
}

# transcribe function
resource "aws_lambda_function" "transcribe_function" {
  function_name    = "transcribe"
  s3_bucket        = aws_s3_object.transcribe_deployment_package.bucket
  s3_key           = aws_s3_object.transcribe_deployment_package.key
  runtime          = "java11"
  handler          = "function.TranscribeFunction::handleRequest"
  source_code_hash = filebase64sha256(aws_s3_object.transcribe_deployment_package.source)
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 500
  memory_size      = 512
  ephemeral_storage { size = 512 }
}

# translate function
resource "aws_lambda_function" "translate_function" {
  function_name    = "translate"
  s3_bucket        = aws_s3_object.translate_deployment_package.bucket
  s3_key           = aws_s3_object.translate_deployment_package.key
  runtime          = "java11"
  handler          = "function.TranslateFunction::handleRequest"
  source_code_hash = filebase64sha256(aws_s3_object.translate_deployment_package.source)
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 500
  memory_size      = 512
  ephemeral_storage { size = 512 }
}

# synthesize function
resource "aws_lambda_function" "synthesize_function" {
  function_name    = "synthesize"
  s3_bucket        = aws_s3_object.synthesize_deployment_package.bucket
  s3_key           = aws_s3_object.synthesize_deployment_package.key
  runtime          = "java11"
  handler          = "function.SynthesizeFunction::handleRequest"
  source_code_hash = filebase64sha256(aws_s3_object.synthesize_deployment_package.source)
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 500
  memory_size      = 512
  ephemeral_storage { size = 512 }
}

# merge function
resource "aws_lambda_function" "merge_function" {
  function_name    = "merge"
  s3_bucket        = aws_s3_object.merge_deployment_package.bucket
  s3_key           = aws_s3_object.merge_deployment_package.key
  runtime          = "java11"
  handler          = "function.MergeFunction::handleRequest"
  source_code_hash = filebase64sha256(aws_s3_object.merge_deployment_package.source)
  role             = data.aws_iam_role.lab_role.arn
  timeout          = 500
  memory_size      = 512
  ephemeral_storage { size = 512 }
}

# ------------------------------------------------------
# IAM
# ------------------------------------------------------

data "aws_iam_role" "lab_role" {
  name     = "LabRole"
}

# ------------------------------------------------------
# LOG GROUPS
# ------------------------------------------------------

resource "aws_cloudwatch_log_group" "split_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.collect_function.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "extract_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.transcribe_function.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "translate_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.translate_function.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "synthesize_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.synthesize_function.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "merge_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.merge_function.function_name}"
  retention_in_days = 14
}

/*

# iam role
resource "aws_iam_role" "admin_role" {
  name               = "admin-role-${random_id.stack_id.hex}"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# iam policy (grants access to all resources)
resource "aws_iam_policy" "admin_policy" {
  name   = "admin_policy-${random_id.stack_id.hex}"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
    ]
  })
}

# bind policy to role
resource "aws_iam_role_policy_attachment" "admin-attach" {
  role       = aws_iam_role.admin_role.name
  policy_arn = aws_iam_policy.admin_policy.arn
}

*/
