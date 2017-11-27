#!/bin/bash

root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../images"

# Build and push container
function build {
	name=$(basename $1)
	cd $1
	echo "Building ninescontrol/$name:latest"
	docker build -t ninescontrol/$name:latest .
	docker push ninescontrol/$name:latest
}

for dir in ${root}/*/
do
	build $dir
done
