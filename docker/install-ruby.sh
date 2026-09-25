#!/bin/sh -x

cd /root

mv /tmp/spec .
mv /tmp/.ashenv .
mv /tmp/exe .
mv /tmp/etc-paths /etc/paths

chmod +x exe/path_helper
chmod +x spec/shell_spec.sh

# Note: The test script will run setup itself
