#!/bin/bash

root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for dir in ${root}/*/
do
	name=$(basename ${dir})
	cd $dir
	echo "Building $name:latest"
	docker build -t $name:latest .
done
