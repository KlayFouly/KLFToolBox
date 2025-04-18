#!/bin/bash

test=$(dirname "$(readlink -f "$0")")
echo "Current directory: $test"