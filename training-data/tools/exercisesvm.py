from __future__ import print_function
import sys
import random
import numpy as np
import itertools
from collections import namedtuple
from sklearn import svm
from sklearn import cross_validation
import exerciseset as eset

default_test_size = 0.7
model_count = 10

def powers(base, low, high):
    return [base**e for e in xrange(low, high + 1)]

default_svm_parameters = (
    {
        'kernel': ['linear'],
        'C': powers(2, -5, 15),
    },
    {
        'kernel': ['rbf'],
        'C': powers(2, -5, 15),
        'gamma': powers(2, -15, 3)
    },
)

SvmResult = namedtuple('SvmResult', ['clf', 'train', 'test', 'score', 'params'])

def svm_parameters_comb(params):
    def prod(param):
        res = ([(k, v) for v in l] for k, l in param.items())
        return [dict(p) for p in list(itertools.product(*res))]

    return itertools.chain(*(prod(p) for p in params))

def dict_format(d):
    return ', '.join(['%s = %s' % (k, v) for k, v in d.items()])

def svm_model(data, target, params, test_size=default_test_size):
    d_train, d_test, t_train, t_test = cross_validation.train_test_split(
            data, target, test_size=test_size)
    clf = svm.SVC(**params).fit(d_train, t_train)
    score = clf.score(d_test, t_test)
    return SvmResult(clf, (d_train, t_train), (d_test, t_test), score, params)

def svm_models(svm_parameters, exerciseset, test_size=default_test_size):
    data = exerciseset[:,1:]
    target = exerciseset[:,0]
    return [svm_model(data, target, params, test_size)
            for params in svm_parameters_comb(svm_parameters)]

if __name__ == '__main__':
    opts = eset.create_arg_parser('Calculate SVM models for exercise set').parse_args()

    print('Searching for CSV files on path: %s' % opts.directory)
    csvpaths = eset.find_csv_files(opts.directory)

    print('Extracting attributes')
    exerciseset = eset.attributes_from_csvfiles(csvpaths, opts.features)

    print('Calculating SVM models with test size %.2f' % default_test_size)
    all_models = svm_models(default_svm_parameters, exerciseset)
    sorted_models = sorted(all_models, reverse=True, key=lambda x: x.score)[:model_count]
    average = sum([model.score for model in sorted_models]) / float(model_count)

    for model in sorted_models:
        print('SVM score %f for params: %s' % (model.score, dict_format(model.params)))

    print('Average of the best %d models: %f' % (model_count, average))

