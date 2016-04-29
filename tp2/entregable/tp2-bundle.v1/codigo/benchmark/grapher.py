#!/usr/bin/env python3

import glob
import json
import matplotlib.ticker as mticker
import numpy as np
import os
import matplotlib.pyplot as plt
import re
import subprocess
import sys

DATA_PATH = "data/"
GRAPHS_PATH = "graphs/"


class Grapher:

    COLORS = [ (r/255., g/255., b/255.) for r,g,b in
             [(31, 119, 180), (174, 199, 232), (255, 127, 14), (255, 187, 120),
             (44, 160, 44), (152, 223, 138), (214, 39, 40), (255, 152, 150),
             (148, 103, 189), (197, 176, 213), (140, 86, 75), (196, 156, 148),
             (227, 119, 194), (247, 182, 210), (127, 127, 127), (199, 199, 199),
             (188, 189, 34), (219, 219, 141), (23, 190, 207), (158, 218, 229)]
    ]

    def __init__(self):
        pass

    def run(self):
        tests = self.loadTests(DATA_PATH)

        if not tests:
            print("No tests found")
            print("Generate some with benchmark.py")
            sys.exit(1)

        if not os.path.exists(GRAPHS_PATH):
            os.makedirs(GRAPHS_PATH)

        self.graphLdrTimeSpeedup(tests, GRAPHS_PATH)

    # Graphs

    def graphLdrTimeSpeedup(self, tests, path):
        # sets: [(cpuModel, {impl: speedup})]
        # groups: [impl]
        sets = []
        groups = []
        for host,t in tests.items():
            if "ldr_implementaciones" not in t["tests"]:
                continue

            datapoints = {}
            base = None

            for result in t["tests"]["ldr_implementaciones"]["results"]:
                if result["implementation"] == "c":
                    base = result["time"]
                else:
                    datapoints[result["implementation"]] = result["time"]

                    if result["implementation"] not in groups:
                        groups.append(result["implementation"])

            # Normalize the data
            datapoints = { i: base/t for i,t in datapoints.items()}

            model = t["model"]
            if model in sets:
                n = 2
                while model+" ("+str(n)+")" in sets:
                    n += 1
                model = model+" ("+str(n)+")"

            sets.append((model,datapoints))

        # Plot the data

        self.plotGroupedBarplots(sets, groups)
        index = np.arange(len(groups))
        bar_width = 0.8 / len(sets)

        plt.xlabel('Extensión', fontsize=14)
        plt.ylabel('Speedup', fontsize=14)
        plt.title('Speedup en tiempo relativo a la implementación en C sobre lena.bmp 512x512', fontsize=16)
        plt.xticks(index + bar_width, groups, fontsize=14)
        plt.yticks(fontsize=14)
        plt.gca().yaxis.set_major_formatter(mticker.FormatStrFormatter('%dx'))
        plt.legend(loc='best')
        plt.ylim(ymin=1.)

        plt.savefig(path+"ldr_time_speedup.png");

    # Utils

    def loadTests(self, dataDir):
        tests = {}
        for filename in glob.glob(os.path.join(dataDir, '*.json')):
            name = os.path.splitext(os.path.basename(filename))[0]

            with open(filename, 'r') as f:
                tests[name] = json.load(f)

        return tests

    def getColor(self,i):
        return self.COLORS[(i) % len(self.COLORS)]

    def setupPyplot(self):
        plt.style.use('ggplot')

        fig, ax = plt.subplots()

        # You typically want your plot to be ~1.33x wider than tall.
        plt.figure(figsize=(12, 9))

        return (fig, ax)

    def plotGroupedBarplots(self, sets, groups):
        # sets: [(label, {group: value})]
        # groups: [impl]
        self.setupPyplot()

        # Order the data in a nice ascending order
        groups = sorted(groups, key = lambda g : -len([1 for s in sets if g in s[1]]))
        sets = sorted(sets, key = lambda s : len(s[1]) * 1000 + s[1][groups[0]])

        index = np.arange(len(groups))
        bar_width = 0.8 / len(sets)

        for i,s in enumerate(sets):
            model, data = s
            ys = [data[g] for g in groups if g in data] + ([0]*(len(groups) - len(data)))

            plt.bar(index + bar_width * (i+0.5) - bar_width * (len(sets)-1) / 2.,
                             ys,
                             bar_width,
                             color = self.getColor(i),
                             label = model)


if __name__ == "__main__":
    g = Grapher()
    g.run()

