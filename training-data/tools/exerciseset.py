from __future__ import print_function
import argparse
import itertools
import os
import fnmatch
import sys
import numpy as np
import extrema

musclegroups = {
    'aerobic': 1,
    'arms': 2,
    'back': 3,
    'chest': 4,
    'core': 5,
    'shoulders': 6,
}

moves = {
    'alt-dumbbell-biceps-curl': 1,
    'angle-chest-press': 2,
    'barbell-biceps-curl': 3,
    'barbell-press': 5,
    'biceps-curl': 6,
    'biceps-curl-hammer': 7,
    'biceps-curl-happer': 7,
    'cable-cross-overs': 9,
    'cable-deltoid-cross-overs': 10,
    'deltoid-row': 11,
    'dumbbell-biceps-curl': 12,
    'dumbbell-chest-fly': 13,
    'dumbbell-chest-press': 14,
    'dumbbell-front-rise': 15,
    'dumbbell-press': 16,
    'dumbbell-row': 17,
    'dumbbell-side-rise': 18,
    'dummbell-chest-press-twist': 19,
    'lat-pulldown-angled': 20,
    'lat-pulldown-straight': 21,
    'leverage-high-row': 22,
    'overhead-pull': 23,
    'pulldown-crunch': 24,
    'rope-biceps-curl': 25,
    'rope-triceps-extension': 26,
    'rowing': 27,
    'side-dips': 28,
    'squat': 29,
    'straight-bar-biceps-curl': 30,
    'straight-bar-triceps-extension': 31,
    'triceps-dips': 32,
    'twist': 34,
}

xyz_start_index = 2
xyz_index = xrange(xyz_start_index, xyz_start_index + 3)

max_mean = 1100
min_mean = -1100
max_std = 900
min_std = 0

csv_converters = {
    0: lambda x: musclegroups.get(x, 0),
    1: lambda x: moves.get(x, 0),
}

def find_csv_files(filepath):
    for root, dirnames, filenames in os.walk(filepath):
        for filename in fnmatch.filter(filenames, '*.csv'):
            yield os.path.join(root, filename)

def data_from_csv(filename):
    return np.genfromtxt(
            filename, delimiter=',', usecols=(0, 1, -3, -2, -1),
            converters=csv_converters, dtype=int)

def arr_to_csv(a):
    return ','.join([str(x) for x in a])

def scale(a, low, high):
    return (a - low) / (high - low)

def label(a):
    # Assuming that the array contains only one kind of exercise move
    musclegroup = a[0][0]
    move = a[0][1]
    return musclegroup * 100 + move

def xyz_arrays(arr):
    return [arr[:,i] for i in xyz_index]

def means(arr):
    return (
        scale(a.mean(), min_mean, max_mean)
        for a in arr
    )

def stds(arr):
    return (
        scale(a.std(), min_std, max_std)
        for a in arr
    )

feature_map = {
    'mean': means,
    'std': stds,
    'extrema': extrema.matching_extrema_flat,
}

all_features = ('mean', 'std', 'extrema')

def attributes_from_array(a, features=all_features):
    l = (label(a),)
    xyz = xyz_arrays(a)
    fs = [feature_map[f](xyz) for f in features]
    attrs = itertools.chain(l, *fs)
    return np.array(list(attrs))

def attributes_from_csvfile(filename, features=all_features):
    data = data_from_csv(filename)
    first = data[0]

    if 0 in first[0:2]:  # Is the muscle group and move known?
        return None

    return attributes_from_array(data, features)

def attributes_from_csvfiles(filenames, features=all_features):
    arrays = (attributes_from_csvfile(csv, features) for csv in filenames)
    arrays = [a for a in arrays if a is not None]  # Filter empty values out
    return np.array(arrays)

def create_arg_parser(description='Parse exercise set'):
    p = argparse.ArgumentParser(description=description)
    p.add_argument('directory', metavar='DIR', type=str, help='Directory to scan CSV from')
    p.add_argument('--features', nargs='+', choices=all_features, type=str,
            default=all_features, help='Features to include in the result')
    return p

if __name__ == '__main__':
    opts = create_arg_parser().parse_args()
    csvpaths = find_csv_files(opts.directory)

    for csvfile in csvpaths:
        attrs = attributes_from_csvfile(csvfile, opts.features)
        if attrs is not None:
            print(arr_to_csv(attrs))

