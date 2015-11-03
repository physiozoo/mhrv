#!/bin/sh

src_dir=$1
dest_dir=$2

# make sure destination exists
mkdir -p "$dest_dir"

for src_file in "$src_dir"/*.{dat,hea,atr}; do
  dest_file="$dest_dir/$(basename $src_file)"
  echo "$src_file -> $dest_file"
  ln -s "$src_file" "$dest_file"
done
