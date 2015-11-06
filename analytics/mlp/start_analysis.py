import sys
from pyspark import SparkContext, SparkConf
from pyspark_cassandra import CassandraSparkContext
import os
from converters import neon2iosmlp
from training.acceleration_dataset import SparkAccelerationDataset
from training.mlp_model import MLPMeasurementModelTrainer
from itertools import groupby
from operator import attrgetter
import uuid


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


def train_model_for_user((info, rows)):
    """"Train a model for the user and a model_id (e.g. 'chest' or 'back')."""
    user_id = info["user_id"]
    model_id = info["model_id"]

    print "Training model '{0}' for user '{1}'".format(model_id, user_id)

    # Make sure the sampled data is in the order it was sampled
    sorted_samples = sorted(rows, key=attrgetter("time"))
    # Group the samples by their exercise session 
    train_examples = [list(samples) for _, samples in groupby(sorted_samples, key=attrgetter("file_name"))]

    dataset = SparkAccelerationDataset(train_examples)
    working_directory = os.path.join(conf["working_directory"], "models", user_id, model_id)

    bin_model, layers, labels = run_training_on(dataset, working_directory)

    return {
        "id": uuid.uuid1(),
        "user_id": user_id,
        "model_id": model_id,
        "model": bin_model,
        "layers": layers,
        "labels": labels
    }


def main(sc):
    """Main entry point. Connects to cassandra and creates a spark job to start training."""
  
    # implement the magic!


if __name__ == '__main__':

    conf = {
        "cassandra": {
            "address": "52.8.10.117",
            "data_keyspace": "training",
            "data_table": "data",
            "model_keyspace": "training",
            "model_table": "models"
        },
        "working_directory": os.path.abspath("../output")
    }

    spark_configuration = SparkConf() \
        .setAppName("Muvr python spark training") \
        .set("spark.cassandra.connection.host", conf["cassandra"]["address"])

    # An external script needs to make sure that all the dependencies are packaged and provided to the workers!
    sc = CassandraSparkContext(conf=spark_configuration)

    sys.exit(main(sc))
