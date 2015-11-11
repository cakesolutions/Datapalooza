import sys
from pyspark import SparkContext, SparkConf
import os
from converters import neon2iosmlp
from training.acceleration_dataset import CSVAccelerationDataset
from training.mlp_model import MLPMeasurementModelTrainer
from itertools import groupby
from operator import attrgetter
import uuid
import shutil

def run_training_on(dataset, working_directory):
    """Create a fresh trainer to train a model on the dataset.
    
    The working directory is used to store intermediate model instances."""
    model_trainer = MLPMeasurementModelTrainer(working_directory)

    trained_model = model_trainer.train(dataset)

    # Extract the ordered labels to map them to the outputs of the network 
    labels = dataset.ordered_labels()
    # Convert the model to a string representation. It can be loaded later to apply it to new data
    str_model = neon2iosmlp.model2string(model_trainer.model_path)
    # Retrieve the layer configuration (number of nodes in each layer) to be able to reconstruct the network
    layer_config = model_trainer.layers(dataset, trained_model)

    return str_model, layer_config, labels 


def train_model_for_directory(dataset_directory):
    """"Train a model for the dataset directory."""
    
    model_name = os.path.basename(dataset_directory)

    print "Training model '{0}'\n".format(model_name)

    working_directory = os.path.join(conf["working_directory"], model_name)

    # Load csv files into the dataset
    dataset = CSVAccelerationDataset(dataset_directory)

    bin_model, layers, labels = run_training_on(dataset, working_directory)

    return {
        "id": uuid.uuid1(),
        "model_name": model_name,
        "model": bin_model,
        "layers": layers,
        "labels": labels
    }


def main(sc):
    """Main entry point. Connects to cassandra and creates a spark job to start training."""
  
    # implement the magic!


if __name__ == '__main__':

    conf = {
        "dataset_directory": os.path.abspath("../../training-data/labelled"),
        "working_directory": os.path.abspath("../output")
    }

    spark_configuration = SparkConf() \
        .setAppName("Muvr python spark training")

    # An external script needs to make sure that all the dependencies are packaged and provided to the workers!
    sc = SparkContext(conf=spark_configuration)

    sys.exit(main(sc))
