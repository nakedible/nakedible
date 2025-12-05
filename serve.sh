#!/bin/sh

zola serve --interface 0.0.0.0 --base-url "https://${CODESPACE_NAME}-1111.app.github.dev/" --no-port-append --drafts
