# Datapalooza
A repository for the combined code of Muvr that would be used during Datapalooza.

[muvr](http://www.muvr.io/) is a demonstration of an application that uses _wearable devices_ (Pebble)—in combination with a mobile app—to submit physical (i.e. accelerometer, compass) and biological (i.e. heart rate) information to a CQRS/ES cluster to be analysed.


# Wearables & mobile session

## Steps for iOS
- Install Cocoapods (latest 0.39.0)
	1. If using HomeBrew `brew install Caskroom/cask/cocoapods`
	2. `sudo gem install cocoapods` 

	Note: Cocoapods needs Ruby in your system
- Install the `pod` dependencies by running `pod install`
- Load `Muvr.xcworkspace` on Xcode
- [Optional] Remove `Pods.Framework` in Xcode dependencies
- Build and run

## Challenge One
Our sensor data is fed in the the classifier in windows 400 samples long. Each sample contains acceleration along the x, y, and z axes. The MLP we trained recognises three exercises: biceps curl, triceps extension, and lateral raise. Its hidden layers have 250 and 100 perceptrons.

- Run the playground and classify the exercise data in the variable sd.
- explore the MKClassifier initializer
- reason about the sizes of the first and last layer
- implement the tanh and sigmoid activation functions
- call the appropriate function on the MKClassifier instance 

## Challenge Two
Using loops to implement the activation functions is not efficient. Our code should make the most of the vector and DSP hardware in modern mobiles.

Instead of `for var i = 0; i < in.count; ++i { in[i] = tanh(in[i]) }`, use `vectlib` and `vDSP` functions. In this example, use the `vvtanhf` function for `tanh`. For `sigmoid`, find and use functions that perform the following in-place operations:

- x ← -x
- x ← e^x
- x ← x + const; in our case x + 1
- x ← x^const; in our case x^-1

use these functions in a better implementation of `tanh` and `sigmoid` AFs.

# Training model session

## Setup Python environment

```bash
cd analytics
./init-env.sh
```
To start development on Python code or notebooks
```bash
source venv/bin/activate
# After you call this line, you should see (venv) added at the beginning of your shell prompt. 
```

## Challenge

- In mlp/training/mlp_model.py, construct the inner layers for the MLP
- Recall that we have 1200 perceptrons in the input layer, then 250, 100 and 3 in the output layer (for 3 labels).
- Construct the layers array to hold
	- `ReLU` layer with 250 perceptrons
	- `ReLU` layer with 100 perceptrons
	- `Sigmoid` (Logistic) layer with as many perceptrons as there are labels (`num_labels`)
- In neon, don’t forget to add a drop-out layer between each layer
- Run the program on a dataset
```
analytics $ python mlp/start_training.py \
  -m chest -d ../training-data/labelled/chest -o ./output
```
- Observe the output; see if you can optimise the hyperparameters 

# Parallelize the computation

## Setup Python environment

*NOTE: You don't need to setup again if you have already ran your environment for the challenge on the previous section*

```bash
cd analytics
./init-env.sh
```
To start development on Python code or notebooks
```bash
source venv/bin/activate
# After you call this line, you should see (venv) added at the beginning of your shell prompt. 
```

## Challenge

- In `start_analysis.py` complete the main method.
- `SparkContext` is already configured and available as `sc`.
- Read data from Cassandra database (keyspace training, table data - see conf)
	The table has the following format
 	`user_id | model_id | file_name | time | x | y | z | exercise`
- Parallelize the computation for each `user_id` and `model_id` combination using training `train_model_for_user` function using Spark
- Run `run_spark.sh` to submit your Spark job to Spark cluster
