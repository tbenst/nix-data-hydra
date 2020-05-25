#!/bin/sh

set -eu
set -f # disable globbing
export IFS=' '

# filter out CUDA to avoind possible license issues
# https://github.com/NixOS/nixpkgs/pull/76233
export NO_CUDA_PATHS=$(echo $OUT_PATHS | sed 's/\s\+/ \n/g' | grep -v cuda | tr -d '\n')
export FILTERED_PATHS=$(echo $OUT_PATHS | sed 's/\s\+/ \n/g' | grep cuda | tr -d '\n')
echo "Ignored the following paths (may be none):\n" $FILTERED_PATHS
echo "Uploading paths:\n" $OUT_PATHS
exec cachix push $NO_CUDA_PATHS