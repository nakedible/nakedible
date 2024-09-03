#!/bin/sh

set -xe

zola build
npx html-export-pdf-cli -i public/resume/index.html -o content/resume/nuutti-kotivuori-resume-a4.pdf -s A4
npx html-export-pdf-cli -i public/resume/index.html -o content/resume/nuutti-kotivuori-resume-letter.pdf -s Letter
