#!/bin/sh -x

cd /tmp

# Build the Crystal binary
shards install
shards build --release --no-debug

# Set up /root directories
cd /root
mkdir -p exe bin

# Move Crystal binary to bin/
mv /tmp/bin/path_helper bin/

# Move Ruby script to exe/ (test script calls "ruby exe/path_helper")
mv /tmp/exe-ruby/path_helper exe/path_helper
chmod +x exe/path_helper

# Move test files
mv /tmp/spec .
mv /tmp/.ashenv .

# Set up /etc/paths
mv /tmp/etc-paths /etc/paths

# Make files executable
chmod +x bin/path_helper
chmod +x spec/shell_spec.sh

# Note: The test script will run setup itself
