#!/bin/bash

# required env:
# - KEYMAP
# - LOCALE
# - TIMEZONE
#
# optional env
# - EXTRA_PACKAGES

set -uo pipefail

pwd
ls -lai
apt update -y
