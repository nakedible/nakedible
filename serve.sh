#!/bin/sh

zola serve --base-url "https://${CODESPACE_NAME}-1111.app.github.dev/" --no-port-append --drafts
