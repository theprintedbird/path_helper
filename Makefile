# Detect container runtime (podman or docker)
CONTAINER_RUNTIME := $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "")

ifeq ($(CONTAINER_RUNTIME),)
$(error Neither podman nor docker found. Please install one of them.)
endif

# Ruby versions to test (matching GitHub Actions matrix)
RUBY_VERSIONS := 2.3.7 2.7 3.2 3.3

# Alpine versions that match the Ruby versions
ALPINE_2_3_7 := 3.8
ALPINE_2_7 := 3.16
ALPINE_3_2 := 3.22
ALPINE_3_3 := 3.22

# Crystal versions to test (matching GitHub Actions matrix)
CRYSTAL_VERSIONS := 1.10.1 1.11.2 1.14.0 latest

# Version detection: use git info for dev, or explicit VERSION env var
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# Docker/Podman image repository
REPO := path_helper

.PHONY: help
help:
	@echo "Path Helper Container Build System"
	@echo ""
	@echo "Container runtime detected: $(CONTAINER_RUNTIME)"
	@echo ""
	@echo "Usage:"
	@echo "  Ruby:"
	@echo "    make build-all              Build images for all Ruby versions"
	@echo "    make build RUBY_VER=2.7     Build image for specific Ruby version"
	@echo "    make test-all               Run tests for all Ruby versions"
	@echo "    make test RUBY_VER=2.7      Run tests for specific Ruby version"
	@echo "    make shell RUBY_VER=2.7     Open interactive shell in container"
	@echo ""
	@echo "  Crystal:"
	@echo "    make build-crystal-all              Build images for all Crystal versions"
	@echo "    make build-crystal CRYSTAL_VER=1.14.0  Build image for specific Crystal version"
	@echo "    make test-crystal-all               Run tests for all Crystal versions"
	@echo "    make test-crystal CRYSTAL_VER=1.14.0   Run tests for specific Crystal version"
	@echo "    make shell-crystal CRYSTAL_VER=latest  Open interactive shell in container"
	@echo ""
	@echo "  General:"
	@echo "    make all                    Build and test both Ruby and Crystal"
	@echo "    make clean                  Remove all built images"
	@echo "    make list                   Show all built images"
	@echo ""
	@echo "Environment Variables:"
	@echo "  VERSION                   Version tag (default: git describe or 'dev')"
	@echo "  RUBY_VERSIONS             Ruby versions to build (default: $(RUBY_VERSIONS))"
	@echo "  CRYSTAL_VERSIONS          Crystal versions to build (default: $(CRYSTAL_VERSIONS))"
	@echo "  CONTAINER_RUNTIME         Override container runtime (podman or docker)"
	@echo ""
	@echo "Examples:"
	@echo "  make build-all                          # Dev build with git-based version"
	@echo "  VERSION=5.0.0 make all                  # Release build both Ruby and Crystal"
	@echo "  make test RUBY_VER=3.3                  # Test specific Ruby version"
	@echo "  make test-crystal CRYSTAL_VER=latest    # Test latest Crystal"

.PHONY: build-all
build-all:
	@echo "Building all Ruby versions with version tag: $(VERSION)"
	@for ruby in $(RUBY_VERSIONS); do \
		echo ""; \
		echo "==> Building Ruby $$ruby..."; \
		alpine_var="ALPINE_$$(echo $$ruby | tr '.' '_')"; \
		alpine_version=$$(eval echo \$$$$alpine_var); \
		$(CONTAINER_RUNTIME) build \
			--build-arg RUBY_VERSION=$$ruby-alpine$$alpine_version \
			--tag $(REPO):$(VERSION)-ruby$$ruby \
			--tag $(REPO):latest-ruby$$ruby \
			-f Dockerfile . || exit 1; \
	done
	@echo ""
	@echo "✓ All images built successfully"
	@echo ""
	@echo "Built images:"
	@$(CONTAINER_RUNTIME) images $(REPO) | grep -E "$(VERSION)|latest"

# Helper function to get Alpine version for a Ruby version
alpine_for_ruby = $(ALPINE_$(subst .,_,$(1)))

.PHONY: build
build:
ifndef RUBY_VER
	@echo "Error: RUBY_VER not specified"
	@echo "Usage: make build RUBY_VER=2.7"
	@exit 1
endif
	@alpine_version=$(call alpine_for_ruby,$(RUBY_VER)); \
	if [ -z "$$alpine_version" ]; then \
		echo "Error: Unknown Ruby version $(RUBY_VER)"; \
		echo "Supported versions: $(RUBY_VERSIONS)"; \
		exit 1; \
	fi; \
	echo "Building Ruby $(RUBY_VER) with Alpine $$alpine_version..."; \
	$(CONTAINER_RUNTIME) build \
		--build-arg RUBY_VERSION=$(RUBY_VER)-alpine$$alpine_version \
		--tag $(REPO):$(VERSION)-ruby$(RUBY_VER) \
		--tag $(REPO):latest-ruby$(RUBY_VER) \
		-f Dockerfile .

.PHONY: test-all
test-all: build-all
	@echo ""
	@echo "Running tests for all Ruby versions..."
	@failed=0; \
	for ruby in $(RUBY_VERSIONS); do \
		echo ""; \
		echo "==> Testing Ruby $$ruby..."; \
		if $(CONTAINER_RUNTIME) run --rm $(REPO):$(VERSION)-ruby$$ruby; then \
			echo "✓ Ruby $$ruby tests passed"; \
		else \
			echo "✗ Ruby $$ruby tests failed"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	echo ""; \
	if [ $$failed -eq 0 ]; then \
		echo "✓ All tests passed!"; \
	else \
		echo "✗ $$failed test suite(s) failed"; \
		exit 1; \
	fi

.PHONY: test
test:
ifndef RUBY_VER
	@echo "Error: RUBY_VER not specified"
	@echo "Usage: make test RUBY_VER=2.7"
	@exit 1
endif
	@echo "Running tests for Ruby $(RUBY_VER)..."
	@$(CONTAINER_RUNTIME) run --rm $(REPO):$(VERSION)-ruby$(RUBY_VER)

.PHONY: shell
shell:
ifndef RUBY_VER
	@echo "Error: RUBY_VER not specified"
	@echo "Usage: make shell RUBY_VER=2.7"
	@exit 1
endif
	@echo "Opening shell in Ruby $(RUBY_VER) container..."
	@$(CONTAINER_RUNTIME) run --rm -ti --entrypoint sh $(REPO):latest-ruby$(RUBY_VER)

.PHONY: clean
clean:
	@echo "Removing all path_helper images..."
	@$(CONTAINER_RUNTIME) images $(REPO) -q | xargs -r $(CONTAINER_RUNTIME) rmi -f || true
	@echo "✓ Cleanup complete"

.PHONY: list
list:
	@echo "Available path_helper images:"
	@$(CONTAINER_RUNTIME) images $(REPO)

# =============================================================================
# Crystal Targets
# =============================================================================

.PHONY: build-crystal-all
build-crystal-all:
	@echo "Building all Crystal versions with version tag: $(VERSION)"
	@for crystal in $(CRYSTAL_VERSIONS); do \
		echo ""; \
		echo "==> Building Crystal $$crystal..."; \
		$(CONTAINER_RUNTIME) build \
			--build-arg CRYSTAL_VERSION=$$crystal \
			--tag $(REPO):$(VERSION)-crystal$$crystal \
			--tag $(REPO):latest-crystal$$crystal \
			-f Dockerfile.crystal . || exit 1; \
	done
	@echo ""
	@echo "✓ All Crystal images built successfully"
	@echo ""
	@echo "Built images:"
	@$(CONTAINER_RUNTIME) images $(REPO) | grep -E "crystal" | grep -E "$(VERSION)|latest"

.PHONY: build-crystal
build-crystal:
ifndef CRYSTAL_VER
	@echo "Error: CRYSTAL_VER not specified"
	@echo "Usage: make build-crystal CRYSTAL_VER=1.14.0"
	@exit 1
endif
	@echo "Building Crystal $(CRYSTAL_VER)..."
	@$(CONTAINER_RUNTIME) build \
		--build-arg CRYSTAL_VERSION=$(CRYSTAL_VER) \
		--tag $(REPO):$(VERSION)-crystal$(CRYSTAL_VER) \
		--tag $(REPO):latest-crystal$(CRYSTAL_VER) \
		-f Dockerfile.crystal .

.PHONY: test-crystal-all
test-crystal-all: build-crystal-all
	@echo ""
	@echo "Running tests for all Crystal versions..."
	@failed=0; \
	for crystal in $(CRYSTAL_VERSIONS); do \
		echo ""; \
		echo "==> Testing Crystal $$crystal..."; \
		if $(CONTAINER_RUNTIME) run --rm $(REPO):$(VERSION)-crystal$$crystal; then \
			echo "✓ Crystal $$crystal tests passed"; \
		else \
			echo "✗ Crystal $$crystal tests failed"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	echo ""; \
	if [ $$failed -eq 0 ]; then \
		echo "✓ All tests passed!"; \
	else \
		echo "✗ $$failed test suite(s) failed"; \
		exit 1; \
	fi

.PHONY: test-crystal
test-crystal:
ifndef CRYSTAL_VER
	@echo "Error: CRYSTAL_VER not specified"
	@echo "Usage: make test-crystal CRYSTAL_VER=1.14.0"
	@exit 1
endif
	@echo "Running tests for Crystal $(CRYSTAL_VER)..."
	@$(CONTAINER_RUNTIME) run --rm $(REPO):$(VERSION)-crystal$(CRYSTAL_VER)

.PHONY: shell-crystal
shell-crystal:
ifndef CRYSTAL_VER
	@echo "Error: CRYSTAL_VER not specified"
	@echo "Usage: make shell-crystal CRYSTAL_VER=1.14.0"
	@exit 1
endif
	@echo "Opening shell in Crystal $(CRYSTAL_VER) container..."
	@$(CONTAINER_RUNTIME) run --rm -ti --entrypoint sh $(REPO):latest-crystal$(CRYSTAL_VER)

# =============================================================================
# Combined Targets
# =============================================================================

.PHONY: all
all: build-all build-crystal-all test-all test-crystal-all
	@echo ""
	@echo "✓ All Ruby and Crystal images built and tested successfully!"

# =============================================================================
# Legacy Targets
# =============================================================================

# Legacy targets for backwards compatibility with Packer workflow
.PHONY: packer-build
packer-build:
	@echo "Warning: Packer has been replaced with Docker"
	@echo "Running: make build-all"
	@$(MAKE) build-all
