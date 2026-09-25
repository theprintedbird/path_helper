# Detect container runtime (podman or docker)
CONTAINER_RUNTIME := $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "")

ifeq ($(CONTAINER_RUNTIME),)
$(error Neither podman nor docker found. Please install one of them.)
endif

# Ruby versions to test (matching GitHub Actions matrix)
RUBY_VERSIONS := 2.7 3.3 4.0.6

# Alpine versions that match the Ruby versions
# 2.6 is not in RUBY_VERSIONS (macOS's deprecated system Ruby, not officially
# supported) but stays buildable on demand: make test RUBY_VER=2.6
ALPINE_2_6 := 3.15
ALPINE_2_7 := 3.16
ALPINE_3_3 := 3.24
ALPINE_4_0_6 := 3.24

# Crystal versions to test (matching GitHub Actions matrix)
CRYSTAL_VERSIONS := 1.10.1 1.11.2 1.14.0 latest

# C library the Crystal images build against: musl (the crystallang/crystal
# *-alpine images, the default) or gnu (the plain tags, which are Ubuntu and
# glibc). gnu images are tagged with a -gnu suffix so the two sit side by side.
CRYSTAL_LIBC ?= musl
ifeq ($(CRYSTAL_LIBC),musl)
CRYSTAL_BASE_SUFFIX := -alpine
CRYSTAL_TAG_SUFFIX :=
else ifeq ($(CRYSTAL_LIBC),gnu)
CRYSTAL_BASE_SUFFIX :=
CRYSTAL_TAG_SUFFIX := -gnu
else
$(error CRYSTAL_LIBC must be musl or gnu, not "$(CRYSTAL_LIBC)")
endif

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
	@echo "    make coverage RUBY_VER=3.3  Run tests with line coverage, report in coverage/ruby/"
	@echo ""
	@echo "  Crystal:"
	@echo "    make build-crystal-all                  Build images for all Crystal versions"
	@echo "    make build-crystal CRYSTAL_VER=1.14.0   Build image for specific Crystal version"
	@echo "    make test-crystal-all                   Run tests for all Crystal versions"
	@echo "    make test-crystal CRYSTAL_VER=1.14.0    Run tests for specific Crystal version"
	@echo "    make shell-crystal CRYSTAL_VER=latest   Open interactive shell in container"
	@echo "    make extract-crystal CRYSTAL_VER=latest Extract binary from container to bin/"
	@echo "    make coverage-crystal CRYSTAL_VER=1.14.0 Run tests with line coverage (kcov, glibc),"
	@echo "                                            report in coverage/crystal/"
	@echo ""
	@echo "  General:"
	@echo "    make all                    Build and test both Ruby and Crystal"
	@echo "    make clean                  Remove all built images"
	@echo "    make list                   Show all built images"
	@echo "    make lint                   Check the test harness for GNU-only shell (breaks on macOS/BSD)"
	@echo ""
	@echo "Environment Variables:"
	@echo "  VERSION                   Version tag (default: git describe or 'dev')"
	@echo "  RUBY_VERSIONS             Ruby versions to build (default: $(RUBY_VERSIONS))"
	@echo "  CRYSTAL_VERSIONS          Crystal versions to build (default: $(CRYSTAL_VERSIONS))"
	@echo "  CRYSTAL_LIBC              C library for the Crystal images: musl (Alpine, default) or gnu (Ubuntu)"
	@echo "  CONTAINER_RUNTIME         Override container runtime (podman or docker)"
	@echo "  TESTS                     Test files to run, e.g. 'path error' (default: all; setup always runs)"
	@echo ""
	@echo "Examples:"
	@echo "  make build-all                          # Dev build with git-based version"
	@echo "  VERSION=5.0.0 make all                  # Release build both Ruby and Crystal"
	@echo "  make test RUBY_VER=3.3                  # Test specific Ruby version"
	@echo "  make test RUBY_VER=3.3 TESTS=path       # Run one test file (after setup)"
	@echo "  make test-crystal CRYSTAL_VER=latest    # Test latest Crystal"
	@echo "  make test-crystal CRYSTAL_VER=1.14.0 CRYSTAL_LIBC=gnu  # Test against glibc"
	@echo "  make coverage RUBY_VER=3.3 TESTS=path   # Coverage of one test file (after setup)"
	@echo ""
	@echo "Notes:"
	@echo "  The test, shell and extract targets build the image they need first,"
	@echo "  so there is no need to run a build target by hand beforehand."
	@echo "  Coverage is a report, not a gate: its exit status is the suite's. Crystal"
	@echo "  coverage always uses its own glibc image (Dockerfile.crystal-coverage),"
	@echo "  whatever CRYSTAL_LIBC is, as kcov does not build against musl."

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
			-f Dockerfile.ruby . || exit 1; \
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
		-f Dockerfile.ruby .

.PHONY: test-all
test-all: build-all
	@echo ""
	@echo "Running tests for all Ruby versions..."
	@failed=0; \
	for ruby in $(RUBY_VERSIONS); do \
		echo ""; \
		echo "==> Testing Ruby $$ruby..."; \
		if $(CONTAINER_RUNTIME) run --rm $(REPO):$(VERSION)-ruby$$ruby $(TESTS); then \
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
	@$(MAKE) build RUBY_VER=$(RUBY_VER)
	@echo "Running tests for Ruby $(RUBY_VER)..."
	@$(CONTAINER_RUNTIME) run --rm $(REPO):$(VERSION)-ruby$(RUBY_VER) $(TESTS)

.PHONY: shell
shell:
ifndef RUBY_VER
	@echo "Error: RUBY_VER not specified"
	@echo "Usage: make shell RUBY_VER=2.7"
	@exit 1
endif
	@$(MAKE) build RUBY_VER=$(RUBY_VER)
	@echo "Opening shell in Ruby $(RUBY_VER) container..."
	@$(CONTAINER_RUNTIME) run --rm -ti --entrypoint sh $(REPO):latest-ruby$(RUBY_VER)

# Line coverage of the Ruby implementation as the suite exercises it. Runs the
# ordinary test image through spec/lib/coverage/run.sh instead of the suite
# directly, so nothing extra is installed; the report lands in coverage/ruby/.
.PHONY: coverage
coverage:
ifndef RUBY_VER
	@echo "Error: RUBY_VER not specified"
	@echo "Usage: make coverage RUBY_VER=3.3"
	@exit 1
endif
	@$(MAKE) build RUBY_VER=$(RUBY_VER)
	@rm -rf coverage/ruby && mkdir -p coverage/ruby
	@echo "Running tests with coverage for Ruby $(RUBY_VER)..."
	@$(CONTAINER_RUNTIME) run --rm -v "$(CURDIR)/coverage/ruby":/coverage:Z \
		--entrypoint sh $(REPO):$(VERSION)-ruby$(RUBY_VER) \
		spec/lib/coverage/run.sh ruby /coverage $(TESTS)
	@echo "Coverage report: coverage/ruby/summary.md"

.PHONY: clean
clean:
	@echo "Removing all path_helper images..."
	@$(CONTAINER_RUNTIME) images $(REPO) -q | xargs -r $(CONTAINER_RUNTIME) rmi -f || true
	@echo "✓ Cleanup complete"

.PHONY: list
list:
	@echo "Available path_helper images:"
	@$(CONTAINER_RUNTIME) images $(REPO)

.PHONY: lint
lint:
	@sh spec/lint_portability.sh

# =============================================================================
# Crystal Targets
# =============================================================================

.PHONY: build-crystal-all
build-crystal-all:
	@echo "Building all Crystal versions ($(CRYSTAL_LIBC)) with version tag: $(VERSION)"
	@for crystal in $(CRYSTAL_VERSIONS); do \
		echo ""; \
		echo "==> Building Crystal $$crystal ($(CRYSTAL_LIBC))..."; \
		$(CONTAINER_RUNTIME) build \
			--build-arg CRYSTAL_VERSION=$$crystal \
			--build-arg CRYSTAL_BASE_SUFFIX=$(CRYSTAL_BASE_SUFFIX) \
			--tag $(REPO):$(VERSION)-crystal$$crystal$(CRYSTAL_TAG_SUFFIX) \
			--tag $(REPO):latest-crystal$$crystal$(CRYSTAL_TAG_SUFFIX) \
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
	@echo "Building Crystal $(CRYSTAL_VER) ($(CRYSTAL_LIBC))..."
	@$(CONTAINER_RUNTIME) build \
		--build-arg CRYSTAL_VERSION=$(CRYSTAL_VER) \
		--build-arg CRYSTAL_BASE_SUFFIX=$(CRYSTAL_BASE_SUFFIX) \
		--tag $(REPO):$(VERSION)-crystal$(CRYSTAL_VER)$(CRYSTAL_TAG_SUFFIX) \
		--tag $(REPO):latest-crystal$(CRYSTAL_VER)$(CRYSTAL_TAG_SUFFIX) \
		-f Dockerfile.crystal .

.PHONY: test-crystal-all
test-crystal-all: build-crystal-all
	@echo ""
	@echo "Running tests for all Crystal versions..."
	@failed=0; \
	for crystal in $(CRYSTAL_VERSIONS); do \
		echo ""; \
		echo "==> Testing Crystal $$crystal ($(CRYSTAL_LIBC))..."; \
		if $(CONTAINER_RUNTIME) run --rm $(REPO):$(VERSION)-crystal$$crystal$(CRYSTAL_TAG_SUFFIX) $(TESTS); then \
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
	@$(MAKE) build-crystal CRYSTAL_VER=$(CRYSTAL_VER)
	@echo "Running tests for Crystal $(CRYSTAL_VER) ($(CRYSTAL_LIBC))..."
	@$(CONTAINER_RUNTIME) run --rm $(REPO):$(VERSION)-crystal$(CRYSTAL_VER)$(CRYSTAL_TAG_SUFFIX) $(TESTS)

.PHONY: shell-crystal
shell-crystal:
ifndef CRYSTAL_VER
	@echo "Error: CRYSTAL_VER not specified"
	@echo "Usage: make shell-crystal CRYSTAL_VER=1.14.0"
	@exit 1
endif
	@$(MAKE) build-crystal CRYSTAL_VER=$(CRYSTAL_VER)
	@echo "Opening shell in Crystal $(CRYSTAL_VER) container..."
	@$(CONTAINER_RUNTIME) run --rm -ti --entrypoint sh $(REPO):latest-crystal$(CRYSTAL_VER)$(CRYSTAL_TAG_SUFFIX)

.PHONY: extract-crystal
extract-crystal:
ifndef CRYSTAL_VER
	@echo "Error: CRYSTAL_VER not specified"
	@echo "Usage: make extract-crystal CRYSTAL_VER=latest"
	@exit 1
endif
	@$(MAKE) build-crystal CRYSTAL_VER=$(CRYSTAL_VER)
	@echo "Extracting Crystal $(CRYSTAL_VER) binary from container..."
	@mkdir -p bin
	@$(CONTAINER_RUNTIME) run --rm --entrypoint sh -v $(PWD):/output:Z $(REPO):latest-crystal$(CRYSTAL_VER)$(CRYSTAL_TAG_SUFFIX) -c "cp /root/bin/path_helper /output/bin/path_helper"
	@echo "✓ Crystal binary extracted to: bin/path_helper"
	@ls -lh bin/path_helper
	@echo ""
	@echo "Test it with: ./bin/path_helper --version"

# Line coverage of the Crystal implementation, measured with kcov against a
# debug build. Uses its own image, Dockerfile.crystal-coverage, which is always
# glibc (Ubuntu) whatever CRYSTAL_LIBC says: kcov is built there from source
# and does not build against musl. kcov needs address randomisation off in the
# process it traces, which the default seccomp profile refuses, hence
# seccomp=unconfined. The report lands in coverage/crystal/.
.PHONY: coverage-crystal
coverage-crystal:
ifndef CRYSTAL_VER
	@echo "Error: CRYSTAL_VER not specified"
	@echo "Usage: make coverage-crystal CRYSTAL_VER=1.14.0"
	@exit 1
endif
	@echo "Building Crystal $(CRYSTAL_VER) coverage image (gnu)..."
	@$(CONTAINER_RUNTIME) build \
		--build-arg CRYSTAL_VERSION=$(CRYSTAL_VER) \
		--tag $(REPO):$(VERSION)-crystal$(CRYSTAL_VER)-coverage \
		-f Dockerfile.crystal-coverage .
	@rm -rf coverage/crystal && mkdir -p coverage/crystal
	@echo "Running tests with coverage for Crystal $(CRYSTAL_VER) (gnu)..."
	@$(CONTAINER_RUNTIME) run --rm --security-opt seccomp=unconfined \
		-v "$(CURDIR)/coverage/crystal":/coverage:Z \
		$(REPO):$(VERSION)-crystal$(CRYSTAL_VER)-coverage $(TESTS)
	@echo "Coverage report: coverage/crystal/summary.md (HTML: coverage/crystal/kcov/index.html)"

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
	@echo "Warning: Packer has been replaced with Docker/Podman"
	@echo "Running: make build-all"
	@$(MAKE) build-all
