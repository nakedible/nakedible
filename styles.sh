#!/bin/sh

set -xe

npx @tailwindcss/cli -i tailwind.css -o static/styles.css -m
