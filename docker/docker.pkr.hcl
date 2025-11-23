variable "ph_version" {
	type = string
}

variable "repo" {
	type    = string
	default = "path_helper"
}

# Define all Ruby versions to test here.
# To add a new Ruby version, just add another entry to this array!
# Current selection tests: legacy (2.3.7), last 2.x (2.7), modern stable (3.2), latest (3.3)
locals {
	rubies = [
		{
			name  = "ph-r237"
			image = "ruby:2.3.7-alpine3.8"
			tag   = "${var.ph_version}-ruby2.3.7"
		},
		{
			name  = "ph-r270"
			image = "ruby:2.7-alpine3.16"
			tag   = "${var.ph_version}-ruby2.7"
		},
		{
			name  = "ph-r320"
			image = "ruby:3.2-alpine3.22"
			tag   = "${var.ph_version}-ruby3.2"
		},
		{
			name  = "ph-r330"
			image = "ruby:3.3-alpine3.22"
			tag   = "${var.ph_version}-ruby3.3"
		}
	]
}

# Single source definition used by all Ruby versions
source "docker" "ph-general" {
	commit  = true
	changes = [
		"ENV PATH_HELPER_DOCKER_INSTANCE=true",
		"WORKDIR /root",
		"ENTRYPOINT [\"spec/shell_spec.sh\"]"
	]
}

build {
	# Dynamically create a source for each Ruby version defined in locals.rubies
	dynamic "source" {
		for_each = local.rubies
		iterator = ruby

		content {
			source = "source.docker.ph-general"
			name   = ruby.value.name
			image  = ruby.value.image
		}
	}

	provisioner "file" {
		source      = "spec"
		destination = "/tmp/spec"
	}

	provisioner "file" {
		source      = "docker/assets/.ashenv"
		destination = "/tmp/.ashenv"
	}

	provisioner "file" {
		source      = "exe"
		destination = "/tmp/exe"
	}

	provisioner "file" {
		source      = "docker/assets/etc-paths"
		destination = "/tmp/etc-paths"
	}

	provisioner "shell" {
		script = "docker/install.sh"
	}

	post-processors {
		post-processor "docker-tag" {
			repository = "${var.repo}"
			tag        = ["${var.ph_version}-${source.name}"]
		}
	}
}
