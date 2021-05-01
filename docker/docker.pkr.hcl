variable "ph_version" {
	type		= string
	default	=	"4.0.0"
}

locals {
	rubies = [
		{
			name 	= "ph-r237"
			image = "ruby:2.3.7-alpine3.8"
			tag 	= "${var.ph_version}-ruby2.3.7"
		},
		{
			name 	= "ph-r270"
			image = "ruby:2.7.0-alpine3.8"
			tag 	= "${var.ph_version}-ruby2.7.0"
		}
	]
}

variable "repo" {
	type		= string
	default = "path_helper"
}

source "docker" "ph-general" {
  commit  = true
	changes = [
		"ENV PATH_HELPER_DOCKER_INSTANCE=true",
		"WORKDIR /root",
		"ENTRYPOINT [\"spec/shell_spec.sh\"]"
	]
}

source "docker" "ph-r270" {
  commit  = true
	changes = [
		"ENV PATH_HELPER_DOCKER_INSTANCE=true",
		"WORKDIR /root",
		"ENTRYPOINT [\"spec/shell_spec.sh\"]"
	]
}


build {
	#	sources = ["source.docker.ph-r270","source.docker.ph-r237"]
	source "source.docker.ph-general" {
		name		=	"ph-r270"
		image   = "ruby:2.7.0-alpine3.11"
	}
	source "source.docker.ph-general" {
		name		=	"ph-r237"
		image   = "ruby:2.3.7-alpine3.8"
	}

	provisioner "file"{
		source			= "spec"
		destination = "/tmp/spec"
	}
	provisioner "file" {
		source			=	"docker/assets/.ashenv"
		destination	=	"/tmp/.ashenv"
	}
	provisioner "file" {
		source			= "exe"
		destination = "/tmp/exe"
	}
	provisioner "file"{
		source			= "docker/assets/etc-paths"
		destination = "/tmp/etc-paths"
	}
  provisioner "shell" {
    script = "docker/install.sh"
  }

	post-processors {
		post-processor "docker-tag" {
			repository	=	"${var.repo}"	
			tag					= ["${var.ph_version}-${source.name}"]
		}
	}
}
