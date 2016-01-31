#!/bin/sh

## build Poly/ML
cd
git clone https://github.com/polyml/polyml
cd polyml
## optionally switch to a released version, e.g., fixes-5.6
# git checkout fixes-5.6
./configure
## optionally pass an installation prefix to configure
# ./configure --prefix=<dir>
## if necessary, put <dir>/bin in your PATH
# export PATH=<dir>/bin:$PATH
make
make compiler
make install

## build HOL
cd
git clone https://github.com/HOL-Theorem-Prover/HOL
cd HOL
## optionally switch to a released version, e.g., kananaskis-11
# git checkout k11-release-prep # kananaskis-11 when released
poly < tools/smart-configure.sml
bin/build
## optionally set HOLDIR to point to the HOL installation
# export HOLDIR=$HOME/HOL
## optionally put $HOLDIR/bin in your PATH
# export PATH=$HOLDIR/bin:$PATH

## build CakeML
cd
git clone https://github.com/CakeML/cakeml
cd cakeml
## optionally switch to a released version, e.g., version1
# git checkout version1
$HOME/HOL/bin/Holmake
## or just Holmake if you set up your PATH as above
# Holmake