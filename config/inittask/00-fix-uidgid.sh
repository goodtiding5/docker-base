#!/bin/sh

set -e

# change group id
groupmod -g ${AS_GID} ${AS_GROUP} > /dev/null 2> /dev/null

# change user id
usermod -u ${AS_UID} ${AS_USER} > /dev/null 2> /dev/null

exit 0
