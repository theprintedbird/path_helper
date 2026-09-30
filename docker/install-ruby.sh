#!/bin/sh -x

cd /root || exit 1

mv /tmp/spec .
mv /tmp/.ashenv .
mv /tmp/exe .
mv /tmp/etc-paths /etc/paths

chmod +x exe/path_helper
chmod +x spec/shell_spec.sh

# Note: The test script will run setup itself
