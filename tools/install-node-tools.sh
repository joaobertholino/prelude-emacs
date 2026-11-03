#!/bin/sh
set -eu
config_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tools_dir="$HOME/.local/share/prelude-tools"
mkdir -p "$tools_dir"
cp "$config_dir/package.json" "$config_dir/package-lock.json" "$tools_dir/"
npm ci --ignore-scripts --prefix "$tools_dir"
