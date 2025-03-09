terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Configure Vault provider with basic auth
provider "vault" {
  address = var.vault_address
  auth_login {
    path = "auth/userpass/login/${var.vault_auth_username}"
    
    parameters = {
      password = var.vault_auth_password
    }
  }
}

# Get Artifactory credentials from Vault
data "vault_generic_secret" "artifactory_creds" {
  path = var.vault_artifactory_secret_path
}

locals {
  image_uri = "${var.artifactory_url}/${var.artifactory_repository}/bedrock-proxy-api:${var.image_tag}"
  pip_conf_path = "${path.module}/docker/pip.conf"
  
  # Validate required files exist
  validate_requirements = fileexists("${path.module}/docker/requirements.txt") ? null : file("ERROR: requirements.txt not found")
  validate_handler = fileexists("${path.module}/docker/app/handler.py") ? null : file("ERROR: handler.py not found")
  
  # Clean up pip.conf path on destroy
  pip_conf_cleanup = "rm -f ${local.pip_conf_path}"
}

# Create pip.conf file for Docker build
resource "local_file" "pip_conf" {
  content  = var.pip_conf_content
  filename = local.pip_conf_path

  # Clean up pip.conf on destroy
  provisioner "local-exec" {
    when    = destroy
    command = local.pip_conf_cleanup
  }
}

# Docker provider configuration (used when use_docker_provider = true)
provider "docker" {
  count = var.use_docker_provider ? 1 : 0
  registry_auth {
    address  = var.artifactory_url
    username = data.vault_generic_secret.artifactory_creds.data["username"]
    password = data.vault_generic_secret.artifactory_creds.data["password"]
  }
}

# Docker image resource (used when use_docker_provider = true)
resource "docker_image" "bedrock_gateway" {
  count = var.use_docker_provider ? 1 : 0
  name  = local.image_uri

  build {
    context    = "${path.module}/docker"
    dockerfile = "Dockerfile"
    build_args = {
      BASE_IMAGE = "public.ecr.aws/lambda/python:3.11"
      PIP_CONF   = "pip.conf"
    }
    # Add labels for better tracking
    labels = {
      "org.opencontainers.image.created" = timestamp()
      "org.opencontainers.image.version" = var.image_tag
    }
  }

  triggers = {
    image_tag = var.image_tag
    dockerfile_hash = fileexists("${path.module}/docker/Dockerfile") ? filesha256("${path.module}/docker/Dockerfile") : ""
    requirements_hash = fileexists("${path.module}/docker/requirements.txt") ? filesha256("${path.module}/docker/requirements.txt") : ""
    app_code_hash = fileexists("${path.module}/docker/app/handler.py") ? filesha256("${path.module}/docker/app/handler.py") : ""
    pip_conf_hash = sha256(var.pip_conf_content)
  }

  depends_on = [local_file.pip_conf]

  lifecycle {
    create_before_destroy = true
  }
}

# Shell command build/push (used when use_docker_provider = false)
resource "null_resource" "docker_build_push" {
  count = var.use_docker_provider ? 0 : 1
  
  triggers = {
    image_tag = var.image_tag
    dockerfile_hash = fileexists("${path.module}/docker/Dockerfile") ? filesha256("${path.module}/docker/Dockerfile") : ""
    requirements_hash = fileexists("${path.module}/docker/requirements.txt") ? filesha256("${path.module}/docker/requirements.txt") : ""
    app_code_hash = fileexists("${path.module}/docker/app/handler.py") ? filesha256("${path.module}/docker/app/handler.py") : ""
    pip_conf_hash = sha256(var.pip_conf_content)
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Verify required files exist
      if [ ! -f "${path.module}/docker/requirements.txt" ]; then
        echo "Error: requirements.txt not found"
        exit 1
      fi
      if [ ! -f "${path.module}/docker/app/handler.py" ]; then
        echo "Error: handler.py not found"
        exit 1
      fi

      # Create pip.conf
      echo '${var.pip_conf_content}' > ${local.pip_conf_path}

      # Build the image
      docker build \
        --build-arg BASE_IMAGE=public.ecr.aws/lambda/python:3.11 \
        --build-arg PIP_CONF=pip.conf \
        --label "org.opencontainers.image.created=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --label "org.opencontainers.image.version=${var.image_tag}" \
        -t ${local.image_uri} \
        -f ${path.module}/docker/Dockerfile ${path.module}/docker

      # Login and push
      docker login ${var.artifactory_url} \
        -u ${data.vault_generic_secret.artifactory_creds.data["username"]} \
        -p ${data.vault_generic_secret.artifactory_creds.data["password"]}
      
      docker push ${local.image_uri}
    EOT
  }

  depends_on = [local_file.pip_conf]
} 