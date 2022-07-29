#!/usr/bin/env python

import json
import os
import re
import argparse

from jinja2 import Environment, PackageLoader, select_autoescape

env = Environment(
    loader=PackageLoader("generate_markdown", package_path="templates"),
    autoescape=select_autoescape()
)

def get_files(path):
    """ Returns all the files in the backtest dir
    """
    dir_list = os.listdir(path)

    return dir_list


def parse_backtest_json(filename):
    """ Parses the backtest-result.json file to extract information
    """

    print("Started Reading JSON file")
    try:
        with open(filename, "r") as read_file:
            print("Starting to convert json decoding")
            json_result = json.load(read_file)

            """print("Decoded JSON Data From File")
            for key, value in backtest.items():
                print(key, ":", value)
            print("Done reading json file")"""
    except FileNotFoundError:
        print("Backtest file not found: {}".format(filename))
        exit()

    return json_result

def parse_backtest_log(filename):
    """ Parses the results.txt file to extract information

    """
    result = {}

    print("Started Reading results file")

    try:
        with open(filename, "r") as read_file:
            buffer = False
            for line in read_file:
                if re.search(r'=+(?P<name>[\w\s]+)=+', line):
                    m = re.search(r'=+(?P<name>[\w\s]+)=+', line).group('name').strip().lower().replace(" ", "_")
                    result.setdefault(m, []).append(line)
                    buffer = True

                if not line.startswith("==") and buffer:
                    result.setdefault(m, []).append(line)
    except FileNotFoundError:
        print("Results file not found: {}".format(filename))
        exit()

    return result

def plot_files(dir_list):
    """ Returns the plot files
    """
    result = {'plot_profit_files': [],
              'plot_dataframe_files': []}

    for f in dir_list:
        if re.match(r'.*freqtrade-profit-plot.*', f):
            result['plot_profit_files'].append(f)
        elif re.match(r'.*freqtrade-plot.*', f):
            result['plot_dataframe_files'].append(f)

    return result

def get_context(filename, args):
    """ Gets some information stored in the context file needed for rendering the Markdown later on
    """
    context = {}
    try:
        with open(filename, "r") as read_file:
            for line in read_file:
                k, v = line.split("=")
                context[k] = v.strip("\n")
    except FileNotFoundError:
        print("Results file not found: {}".format(filename))
        exit()
    except ValueError:
        print("There is something wrong with the context file. Rerun make backtest, make keep, or manually fix the context.txt file: {}".format(filename))
        exit()

    """if os.path.exists(os.path.join(args.path + args.strategy + ".json")):
        context["parameters_file"] = "{}.json".format(args.strategy)

    context = { "id": "2022-07-23_07-33-14",
            "config_file": "pierre_config.json",
            "parameters_file": "Pierre.json",
            "strategy_file": "Pierre.py",
            "results_file": "results.txt",
            }"""

    return context


def main():
    """
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=str,
                        help="path where results are stored")
    parser.add_argument("--strategy", type=str,
                        help="Strategy used")
    parser.add_argument("--id", type=str,
                        help="id of the backtest")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="increase output verbosity")
    args = parser.parse_args()
        
    dir_list = get_files(args.path)
    print(dir_list)

    json_result = parse_backtest_json(os.path.join(args.path, "backtest-result-" + args.id + ".json"))
    log_result = parse_backtest_log(os.path.join(args.path, "results-" + args.id + ".txt"))
    plots = plot_files(dir_list)
    context = get_context(os.path.join(args.path, "context-" + args.id + ".txt"), args)


    template = env.get_template("backtest-result.j2")
    print(template.render(log_result=log_result, 
                          json_result=json_result, 
                          plot_files=plots,
                          context=context))

    output_file = os.path.join(args.path, args.id + ".md")
    with open(output_file, "w") as fh:
        fh.write(template.render(log_result=log_result, 
                                 json_result=json_result, 
                                 plot_files=plots,
                                 context=context))

if __name__ == "__main__":
    main()