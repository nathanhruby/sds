#!/bin/bash -e
vagrant box update
vagrant up
vagrant package
vagrant box add --name sds-base --force ./package.box
vagrant destroy -f
rm -rf .vagrant package.box