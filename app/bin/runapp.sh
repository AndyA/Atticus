#!/bin/bash

#./setup.sh

plackup -R lib,config.yml -s HTTP::Server::Simple --nproc 10 --port 9090 bin/app.pl

# vim:ts=2:sw=2:sts=2:et:ft=sh

