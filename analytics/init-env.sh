#!/bin/bash
set -xe

# Install pip
if ! [ `command -v pip` ]
then
  sudo easy_install pip
fi

# Create virtual env
VENV=venv
sudo pip2.7 install virtualenv
sudo rm -rf $VENV
virtualenv $VENV -p /usr/bin/python2.7
source $VENV/bin/activate

# Install dependencies
pip2.7 install --download-cache=cache -r muvr.pip

# Insteall neon latest
git clone --branch v1.1.0 https://github.com/NervanaSystems/neon.git $VENV/neon
cd $VENV/neon
make sysinstall
cd -

# Install mlp
cd mlp
python setup.py install
cd -

# Install Spark
cd $VENV

if ! [ `command -v pv` ]
then
  brew install pv
fi
curl http://mirror.catn.com/pub/apache/spark/spark-1.5.1/spark-1.5.1-bin-hadoop2.6.tgz -o spark-1.5.1-bin-hadoop2.6.tgz
[ $(pv spark-1.5.1-bin-hadoop2.6.tgz | tar xzf -) ] || tar xzf spark-1.5.1-bin-hadoop2.6.tgz

cd -
SPARK_HOME=`pwd`/$VENV/spark-1.5.1-bin-hadoop2.6
cat >> $VENV/bin/activate << EOF
export SPARK_HOME=$SPARK_HOME
export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/build:$PYTHONPATH
export PATH=$SPARK_HOME/bin:$PATH
EOF
source $VENV/bin/activate
