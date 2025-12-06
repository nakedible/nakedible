#!/bin/sh

# Watch script for resume development
# Run alongside ./serve.sh when editing resume.html or tailwind.css
#
# Watches for changes to:
# - templates/resume.html
# - tailwind.css
# - tailwind.config.js
#
# On change: rebuilds Tailwind CSS and regenerates PDFs

set -e

echo "Starting resume watch mode..."
echo "Watching: templates/resume.html, tailwind.css, tailwind.config.js"
echo "Press Ctrl+C to stop"
echo

rebuild() {
    echo "==> Rebuilding Tailwind CSS..."
    npx @tailwindcss/cli -i tailwind.css -o static/styles.css -m

    echo "==> Rebuilding site..."
    zola build

    echo "==> Regenerating PDFs..."
    npx html-export-pdf-cli -i public/resume/index.html -o content/resume/nuutti-kotivuori-resume-a4.pdf -s A4
    npx html-export-pdf-cli -i public/resume/index.html -o content/resume/nuutti-kotivuori-resume-letter.pdf -s Letter

    echo "==> Done at $(date +%H:%M:%S)"
    echo
}

# Initial build
rebuild

# Watch for changes using inotifywait if available, otherwise poll
if command -v inotifywait >/dev/null 2>&1; then
    while inotifywait -q -e modify templates/resume.html tailwind.css tailwind.config.js; do
        rebuild
    done
else
    echo "(inotifywait not found, using polling every 2s)"
    LAST_HASH=""
    while true; do
        HASH=$(cat templates/resume.html tailwind.css tailwind.config.js 2>/dev/null | md5sum)
        if [ "$HASH" != "$LAST_HASH" ] && [ -n "$LAST_HASH" ]; then
            rebuild
        fi
        LAST_HASH="$HASH"
        sleep 2
    done
fi
