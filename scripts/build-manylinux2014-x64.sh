#!/usr/bin/env bash
set -eaux

INSTALL_NETCDF=0
INSTALL_NETCDF=${INSTALL_CAIRO:=1}
INSTALL_NETCDF=${INSTALL_NETCDF:=1}
INSTALL_NETCDF=${INSTALL_PANGO:=1}

./scripts/build-linux.sh
