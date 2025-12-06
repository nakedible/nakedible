#!/bin/sh

# One-shot resume build: Tailwind CSS, site rebuild, and PDF generation
# For watch mode, use ./resume-watch.sh instead

set -xe

# Download Tailwind standalone CLI if not present
TAILWIND_VERSION="v4.1.17"
TAILWIND_BIN="$(dirname "$0")/.tailwindcss"
if [ ! -x "$TAILWIND_BIN" ]; then
    curl -sL "https://github.com/tailwindlabs/tailwindcss/releases/download/${TAILWIND_VERSION}/tailwindcss-linux-x64" -o "$TAILWIND_BIN"
    chmod +x "$TAILWIND_BIN"
fi

$TAILWIND_BIN -i tailwind.css -o static/styles.css -m
zola build
npx html-export-pdf-cli -i public/resume/index.html -o content/resume/nuutti-kotivuori-resume-a4.pdf -s A4
npx html-export-pdf-cli -i public/resume/index.html -o content/resume/nuutti-kotivuori-resume-letter.pdf -s Letter
