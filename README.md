# sds
Software Defined Stack Lab

## Setup

- `brew cask install vagrant virtualbox`
- `cd base-box && ./build.sh && cd -`
- `vagrant up`

## Using
- `vagrant ssh box-1`
- `export NOMAD_ADDR=http://192.168.78.11:4646`
- `noamd status`
- `cd /vagrant/nomad-jobs`
- `nomad run 00_portworx.nomad`
