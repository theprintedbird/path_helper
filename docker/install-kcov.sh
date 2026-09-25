#!/bin/sh
#
# Installs kcov (https://github.com/SimonKagstrom/kcov), which is how the
# Crystal implementation's coverage is measured: Crystal has no coverage tool
# of its own, and kcov reads any binary's DWARF line table instead.
#
# Neither Ubuntu 24.04 (the glibc crystallang/crystal images and the hosted
# ubuntu-latest runner) nor Alpine packages kcov, so it is built from a release
# tarball. apt only: kcov is not known to build against musl, so Crystal
# coverage is measured on glibc (see the Makefile's coverage-crystal target).
#
# KCOV_PREFIX (env, default /usr/local) is where kcov is installed. It exists
# so the Crystal coverage CI job can point it at a directory under $HOME and
# cache the build across runs (see .github/workflows/test-crystal.yml);
# Dockerfile.crystal-coverage leaves it at the default, unchanged. On a cache
# hit -- an executable already at $KCOV_PREFIX/bin/kcov -- only the runtime
# libraries kcov links (libcurl, libdw/libelf, zlib, libstdc++; found by `ldd`
# on a built binary) are installed, since the runner image isn't guaranteed to
# have libdw/libelf; if the binary then runs, the build is skipped.
#
# Used by Dockerfile.crystal-coverage (as root) and by the Crystal coverage job
# in .github/workflows/test-crystal.yml (as the runner user, with sudo), hence
# POSIX sh and sudo only when not already root. `make install` is only run
# under sudo if KCOV_PREFIX (or its nearest existing ancestor) isn't writable
# by the current user, so an under-$HOME prefix on the runner doesn't need it.
#
# Usage: docker/install-kcov.sh [version]   (default: v43)

set -e

KCOV_VERSION="${1:-v43}"
KCOV_PREFIX="${KCOV_PREFIX:-/usr/local}"

as_root=""
[ "$(id -u)" -eq 0 ] || as_root=sudo

if ! command -v apt-get >/dev/null 2>&1; then
	echo "install-kcov.sh: only apt-based systems are supported (kcov does not build on musl)" >&2
	exit 1
fi

$as_root env DEBIAN_FRONTEND=noninteractive apt-get update

kcov_bin="$KCOV_PREFIX/bin/kcov"
if [ -x "$kcov_bin" ]; then
	# A restored build: install only the runtime libraries it links against
	# (see the header comment). The names carry Ubuntu 24.04's "t64" suffix,
	# which is safe here because the CI cache key includes the Ubuntu release;
	# a fresh build (as in Dockerfile.crystal-coverage, on any Ubuntu) never
	# gets here.
	$as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libcurl4t64 libdw1t64 libelf1t64 zlib1g libstdc++6
	if "$kcov_bin" --version >/dev/null 2>&1; then
		echo "kcov already installed: $kcov_bin"
		exit 0
	fi
fi

$as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	ca-certificates curl cmake g++ make python3 \
	binutils-dev libcurl4-openssl-dev libdw-dev libiberty-dev libssl-dev zlib1g-dev

build_dir=$(mktemp -d)
curl -fsSL "https://github.com/SimonKagstrom/kcov/archive/refs/tags/$KCOV_VERSION.tar.gz" |
	tar -xz -C "$build_dir" --strip-components=1
mkdir "$build_dir/build"
(
	cd "$build_dir/build"
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$KCOV_PREFIX" ..
	make -j "$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"

	# sudo only if needed: walk up to the nearest existing ancestor of
	# KCOV_PREFIX (which `make install` will create) and check that.
	install_as_root=""
	dir="$KCOV_PREFIX"
	while [ ! -d "$dir" ]; do
		dir=$(dirname "$dir")
	done
	[ -w "$dir" ] || install_as_root=sudo

	$install_as_root make install
)
rm -rf "$build_dir"

"$kcov_bin" --version
