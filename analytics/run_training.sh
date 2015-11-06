#!/bin/bash

mkdir -p dataset
mkdir -p output

if [ -z "$1" ]
then
    DATASET="dataset/*.zip"
else
    DATASET=$1
fi
if [ -z "$2" ]
then
    OUTPUT="output"
else
    OUTPUT=$2
fi
VISUAL="$OUTPUT/visualisation.png"
EVAL="$OUTPUT/evaluation.csv"

rm -f $VISUAL
rm -f $EVAL

python mlp/start_training.py -h
printf "\n\nSTART TRAINING & EVALUATION\n\n"

if [ -z "$3" ]
then
    python mlp/start_training.py -d $DATASET -o $OUTPUT -e $EVAL -v $VISUAL
else
    python mlp/start_training.py -d $DATASET -o $OUTPUT -e $EVAL -v $VISUAL -t $3
fi
EXIT_CODE=$?
if [[ $EXIT_CODE != 0 ]]
then
    exit $EXIT_CODE
else
    open $OUTPUT/visualisation.png
    open $OUTPUT/evaluation.csv
fi
