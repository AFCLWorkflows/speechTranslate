#!/usr/bin/env/python
import json

# read credentials json file
f = open('credentials.json')
credentials = json.load(f)
aws_credentials=credentials["aws_credentials"]
gcp_credentials=credentials["gcp_credentials"]
google_project_id=gcp_credentials["project_id"]

# Functions
credentials_json = json.dumps(credentials, indent=2)
with open("collect/src/main/resources/credentials.json", "w") as outfile:
    outfile.write(credentials_json)
with open("transcribe/src/main/resources/credentials.json", "w") as outfile:
    outfile.write(credentials_json)
with open("translate/src/main/resources/credentials.json", "w") as outfile:
    outfile.write(credentials_json)
with open("synthesize/src/main/resources/credentials.json", "w") as outfile:
    outfile.write(credentials_json)
with open("merge/src/main/resources/credentials.json", "w") as outfile:
    outfile.write(credentials_json)

# xAFCL
sa_key=json.dumps(gcp_credentials).replace("%", "%%").replace("'", "\"").replace(", ", ",\\\n").replace("{", "{\\\n").replace("}", "\\\n}").replace("\\n", "\\\\n")
credentials_properties=f"""
aws_access_key_id={aws_credentials["access_key"]}
aws_secret_access_key={aws_credentials["secret_key"]}
google_sa_key={sa_key}
"""
with open("workflow/credentials.properties", "w") as outfile:
    outfile.write(credentials_properties)

# Terraform
variables_tf=f"""
resource "random_id" "stack_id" {{
  byte_length = 8
}}
variable "aws_access_key" {{
  default = "{aws_credentials["access_key"]}"
}}
variable "aws_secret_key" {{
  default = "{aws_credentials["secret_key"]}"
}}
variable "aws_session_token" {{
  default = "{aws_credentials["token"]}"
}}
variable "google_project_id" {{
  default = "{google_project_id}"
}}
"""
with open("variables.tf", "w") as outfile:
    outfile.write(variables_tf)
