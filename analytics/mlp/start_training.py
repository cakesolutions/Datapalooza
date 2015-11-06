import sys
import argparse
import os
import numpy as np
import csv

from sklearn.metrics import confusion_matrix
from training.acceleration_dataset import CSVAccelerationDataset
from training.mlp_model import MLPMeasurementModelTrainer
from converters import neon2iosmlp
from pylab import *


def visualise_dataset(dataset, output_image):
    """Visualise partly the dataset and save as image file"""

    # Choose some random examples to plot from the training data
    number_of_examples_to_plot = 3
    plot_ids = np.random.random_integers(0, dataset.num_train_examples - 1, number_of_examples_to_plot)

    print "Ids of plotted examples:", plot_ids

    # Retrieve a human readable label given the idx of an example
    def label_of_example(index):
        return dataset.human_label_for(dataset.y_train[index])

    figure(figsize=(20, 10))
    ax1 = subplot(311)
    setp(ax1.get_xticklabels(), visible=False)
    ax1.set_ylabel('X - Acceleration')

    ax2 = subplot(312, sharex=ax1)
    setp(ax2.get_xticklabels(), visible=False)
    ax2.set_ylabel('Y - Acceleration')

    ax3 = subplot(313, sharex=ax1)
    ax3.set_ylabel('Z - Acceleration')

    for i in plot_ids:
        c = np.random.random((3,))

        ax1.plot(range(0, dataset.num_features / 3), dataset.X_train[i, 0:400], '-o', c=c)
        ax2.plot(range(0, dataset.num_features / 3), dataset.X_train[i, 400:800], '-o', c=c)
        ax3.plot(range(0, dataset.num_features / 3), dataset.X_train[i, 800:1200], '-o', c=c)

    legend(map(label_of_example, plot_ids))
    suptitle('Feature values for the first three training examples', fontsize=16)
    xlabel('Time')
    savefig(output_image)


def learn_model_from_data(dataset, working_directory, model_name):
    """Use MLP to train the dataset and generate result in working_directory"""
    model_trainer = MLPMeasurementModelTrainer(working_directory)

    trained_model = model_trainer.train(dataset)

    dataset.save_labels(os.path.join(working_directory, model_name + '_model.labels.txt'))
    neon2iosmlp.convert(model_trainer.model_path, os.path.join(working_directory, model_name + '_model.weights.raw'))

    layers = model_trainer.layers(dataset, trained_model)
    neon2iosmlp.write_layers_to_file(layers, os.path.join(working_directory, model_name + '_model.layers.txt'))

    return model_trainer, trained_model


def predict(model, dataset):
    """Calculate the prediction of dataset with trained model"""
    dataset.reset()
    predictions = None
    nprocessed = 0
    for x, t in dataset:
        pred = model.fprop(x, inference=True).asnumpyarray()
        bsz = min(dataset.ndata - nprocessed, model.be.bsz)
        nprocessed += bsz
        if predictions is None:
            predictions = pred[:, :bsz]
        else:
            predictions = np.hstack((predictions, pred[:, :bsz]))
    return predictions


def show_evaluation(model, dataset):
    """Generate the evaluation table"""
    # confusion_matrix(y_true, y_pred)
    predicted = predict(model, dataset.test())
    y_true = dataset.y_test
    y_pred = np.argmax(predicted, axis=0)

    confusion_mat = confusion_matrix(y_true, y_pred, range(0, dataset.num_labels))

    # Fiddle around with cm to get it into table shape
    confusion_mat = np.vstack((np.zeros((1, dataset.num_labels), dtype=int), confusion_mat))
    confusion_mat = np.hstack((np.zeros((dataset.num_labels + 1, 1), dtype=int), confusion_mat))

    table = confusion_mat.tolist()

    human_labels = map(dataset.human_label_for, range(0, dataset.num_labels))

    for i, s in enumerate(human_labels):
        table[0][i+1] = s
        table[i+1][0] = s
    table[0][0] = "actual \ predicted"

    return table


def write_to_csv(filename, data):
    """Write csv data to filename"""
    csvfile = open(filename, 'wb')
    writer = csv.writer(csvfile)
    writer.writerows(data)
    csvfile.close()


def main(dataset_directory, working_directory, evaluation_file, visualise_image, model_name, test_directory):
    """Main entry point."""

    # 1/ Load the dataset
    dataset = CSVAccelerationDataset(dataset_directory, test_directory)
    print "Number of training examples:", dataset.num_train_examples
    print "Number of test examples:", dataset.num_test_examples
    print "Number of features:", dataset.num_features
    print "Number of labels:", dataset.num_labels

    # 2/ Visualise the dataset
    visualise_dataset(dataset, visualise_image)

    # 3/ Train the dataset using MLP
    mlpmodel, trained_model = learn_model_from_data(dataset, working_directory, model_name)

    # 4/ Evaluate the trained model
    table = show_evaluation(trained_model, dataset)

    # 5/ Print the evaluation table to csv file
    write_to_csv(evaluation_file, table)
    
if __name__ == '__main__':
    """List arguments for this program"""
    parser = argparse.ArgumentParser(description='Train and evaluate the exercise dataset.')
    parser.add_argument('-d', metavar='dataset', type=str, help="folder containing exercise dataset")
    parser.add_argument('-t', metavar='test', type=str, help="test dataset")
    parser.add_argument('-o', metavar='output', default='./output', type=str, help="folder containing generated model")
    parser.add_argument('-e', metavar='evaluation', default='./output/evaluation.csv', type=str, help="evaluation csv file output")
    parser.add_argument('-v', metavar='visualise', default='./output/visualisation.png', type=str, help="visualisation dataset image output")
    parser.add_argument('-m', metavar='modelname', default='demo', type=str, help="prefix name of model")
    args = parser.parse_args()

    #
    # A good example of command-line params is
    # -m core -d ../../muvr-training-data/labelled/core -o ../output/ -v ../output/v.png -e  ../output/e.csv
    #
    sys.exit(main(args.d, args.o, args.e, args.v, args.m, args.t))
