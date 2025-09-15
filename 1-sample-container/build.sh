#!/bin/bash
# Build script for hello.c
# Compiles hello.c to /opt/hello
set -e

gcc /opt/hello.c -o /opt/hello
chmod +x /opt/hello
