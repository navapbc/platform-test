#!/bin/sh
wget --no-verbose --tries=1 --spider http://localhost:$PORT/health || exit 1
