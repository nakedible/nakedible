#!/bin/sh

set -xe

npx tailwindcss -i tailwind.css -o static/styles.css -m
