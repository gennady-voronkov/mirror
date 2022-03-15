#!/bin/bash
#
#Author Gennady Voronkov
#
/usr/sbin/drbdadm primary mirror
mount -o nospace_cache,recovery /dev/drbd0 /replica
