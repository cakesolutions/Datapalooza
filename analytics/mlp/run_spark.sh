#!/bin/bash

# Package the app as a zip container with all dependencies to be run on different nodes
python setup.py sdist --formats=zip

# Submit the build package to spark for execution
spark-submit \
  --py-files dist/muvr-analysis-mlp-1.0-SNAPSHOT.zip \
  --master local[8] \
  start_analysis.py