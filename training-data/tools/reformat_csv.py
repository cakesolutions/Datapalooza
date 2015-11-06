import sys
import argparse
import csv
import os


def load_csv(filename):
    """Read csv into array of lines"""
    with open(filename, 'rb') as csvfile:
        dialect = csv.Sniffer().sniff(csvfile.read(1024))
        csvfile.seek(0)
        csv_data = csv.reader(csvfile, dialect)
        data = []
        for row in csv_data:
            data.append(row)
    return data


def write_to_csv(filename, data):
    """Write csv data to filename"""
    file = open(filename, 'wb')
    writer = csv.writer(file)
    writer.writerows(data)
    file.close()

def list_filter_dirs(path, filter):
    """List all file/directory under path and apply filter function on the result"""
    all = os.listdir(path)
    subdirs = []
    for f in all:
        fullpath = os.path.join(path, f)
        if filter(fullpath):
            subdirs.append(fullpath)
    return subdirs


def create_new_csv_row(X, Y, Z, exercise, intensity, weight, repetition):
    new_row = []
    new_row.append(float(X) / 1000)
    new_row.append(float(Y) / 1000)
    new_row.append(float(Z) / 1000)
    new_row.append(exercise)
    if intensity == '':
        new_row.append('')
    else:
        new_row.append(float(intensity))
    if weight == '':
        new_row.append('')
    else:
        new_row.append(float(weight))
    if repetition == '':
        new_row.append('')
    else:
        new_row.append(int(repetition))
    return new_row


def reformat_csv_data(data):
    """ New format:
        X | Y | Z | biceps-curl | intensity | weight | repetition
    """
    new_data = []
    for row in data:
        new_row = []
        if len(row) == 7:
            # Format of this file: Model | exercise | weight | repetition | X | Y | Z
            new_row = create_new_csv_row(row[4], row[5], row[6], row[1], '', row[2], row[3])
        elif len(row) == 8:
            # Format of this file: Model | exercise | angle | weight | repetition | X | Y | Z
            # Format of this file: Model | exercise | extra | weight | repetition | X | Y | Z
            new_row = create_new_csv_row(row[5], row[6], row[7], row[1], '', row[3], row[4])
        elif len(row) == 5:
            new_row = create_new_csv_row(row[2], row[3], row[4], row[1], '', '', '')
        if len(new_row) == 7:
            new_data.append(new_row)
    return new_data


def main(input_directory, output_directory, folder_csv):
    """Main entry point."""

    is_dir = lambda dir: os.path.isdir(dir)
    is_csv_file = lambda file: os.path.isfile(file) and file.endswith("csv")

    count = 0

    if folder_csv is None:
        all_model_dir = list_filter_dirs(input_directory, is_dir)
        for model_dir in all_model_dir:
            all_sub_dir = list_filter_dirs(model_dir, is_dir)
            for sub_dir in all_sub_dir:
                all_csv = list_filter_dirs(sub_dir, is_csv_file)
                for csv_file in all_csv:
                    data = load_csv(csv_file)
                    new_data = reformat_csv_data(data)
                    new_name = csv_file.replace("/", "_").replace("\\", "_")
                    if output_directory == '':
                        final_output = os.path.join(model_dir, new_name)
                    else:
                        final_output = os.path.join(output_directory, new_name)
                    write_to_csv(final_output, new_data)
                    count += 1
    else:
        all_csv = list_filter_dirs(folder_csv, is_csv_file)
        for csv_file in all_csv:
            data = load_csv(csv_file)
            new_data = reformat_csv_data(data)
            new_name = os.path.basename(csv_file)
            # print os.path.join(output_directory, new_name)
            write_to_csv(os.path.join(output_directory, new_name), new_data)
            count += 1
    print "Finish converting %d csv files" % count


if __name__ == '__main__':
    """List arguments for this program"""
    parser = argparse.ArgumentParser(description='Convert old format csv to the new one.')
    # Convert all csv at this path: labelled/model*/user*/*.csv ==> labelled/model*/*.csv
    parser.add_argument('-l', metavar='input', default='labelled', type=str, help="labelled folder containing old format csv")
    parser.add_argument('-f', metavar='folder', type=str, help="folder contain csv")
    parser.add_argument('-o', metavar='output', default='', type=str, help="output folder")
    args = parser.parse_args()

    sys.exit(main(args.l, args.o, args.f))
