#!/bin/sh
#
# Builds and installs kcov (https://github.com/SimonKagstrom/kcov), which is
# how the Crystal implementation's coverage is measured: Crystal has no coverage
# tool of its own, and kcov reads any binary's DWARF line table instead.
#
# Neither Ubuntu 24.04 (the glibc crystallang/crystal images and the hosted
# ubuntu-latest runner) nor Alpine packages kcov, so it is built from a release
# tarball. apt only: kcov is not known to build against musl, so Crystal
# coverage is measured on glibc (see the Makefile's coverage-crystal target).
#
# Used by Dockerfile.crystal-coverage (as root) and by the Crystal coverage job
# in .github/workflows/test-crystal.yml (as the runner user, with sudo), hence
# POSIX sh and sudo only when not already root.
#
# Usage: docker/install-kcov.sh [version]   (default: v43)

set -e

KCOV_VERSION="${1:-v43}"

as_root=""
[ "$(id -u)" -eq 0 ] || as_root=sudo

if command -v kcov >/dev/null 2>&1; then
	echo "kcov already installed: $(command -v kcov)"
	exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
	echo "install-kcov.sh: only apt-based systems are supported (kcov does not build on musl)" >&2
	exit 1
fi

$as_root env DEBIAN_FRONTEND=noninteractive apt-get update
$as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	ca-certificates curl cmake g++ make python3 \
	binutils-dev libcurl4-openssl-dev libdw-dev libiberty-dev libssl-dev zlib1g-dev

build_dir=$(mktemp -d)
curl -fsSL "https://github.com/SimonKagstrom/kcov/archive/refs/tags/$KCOV_VERSION.tar.gz" |
	tar -xz -C "$build_dir" --strip-components=1
mkdir "$build_dir/build"
(
	cd "$build_dir/build"
	cmake -DCMAKE_BUILD_TYPE=Release ..
	make -j "$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
	$as_root make install
)
rm -rf "$build_dir"

kcov --version
