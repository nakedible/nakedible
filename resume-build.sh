#!/bin/sh

# One-shot resume build: Tailwind CSS, site rebuild, and PDF generation
# For watch mode, use ./resume-watch.sh instead

set -xe

npx @tailwindcss/cli -i tailwind.css -o static/styles.css -m
zola build
npx html-export-pdf-cli -i public/resume/index.html -o content/resume/nuutti-kotivuori-resume-a4.pdf -s A4
npx html-export-pdf-cli -i public/resume/index.html -o content/resume/nuutti-kotivuori-resume-letter.pdf -s Letter
