#!/bin/bash

echo "Calculating checksum"
DMGNAME=$(find /tmp/artifacts -name "gimp-3.*.dmg")
shasum -a 256 "${DMGNAME}" > "${DMGNAME}.sha256"
echo "Checksum: $(cat "${DMGNAME}.sha256")"
