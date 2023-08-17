
resource "random_id" "stack_id" {
  byte_length = 8
}
variable "aws_access_key" {
  default = ""
}
variable "aws_secret_key" {
  default = ""
}
variable "aws_session_token" {
  default = ""
}
variable "google_project_id" {
  default = ""
}
