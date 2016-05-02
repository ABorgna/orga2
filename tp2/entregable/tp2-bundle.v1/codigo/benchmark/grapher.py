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
        self.modelColors = {}

    def run(self):
        tests = self.loadTests(DATA_PATH)

        if not tests:
            print("No tests found")
            print("Generate some with benchmark.py")
            sys.exit(1)

        if not os.path.exists(GRAPHS_PATH):
            os.makedirs(GRAPHS_PATH)

        self.plotTime(tests, "cropflip", GRAPHS_PATH)
        self.plotSpeedup(tests, "cropflip", GRAPHS_PATH)
        self.plotTime(tests, "sepia", GRAPHS_PATH)
        self.plotSpeedup(tests, "sepia", GRAPHS_PATH)
        self.plotTime(tests, "ldr", GRAPHS_PATH)
        self.plotSpeedup(tests, "ldr", GRAPHS_PATH)

    # Graphs

    def plotTime(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (minTime, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []
        maxMinTime = 0.

        for host,t in tests.items():
            if filterName+"_implementaciones" not in t["tests"]:
                continue

            datapoints = {}
            base = None

            for result in t["tests"][filterName+"_implementaciones"]["results"]:
                datapoints[result["implementation"]] = (
                        result["avgTime"],
                        result["maxTime"] - result["avgTime"],
                        result["avgTime"] - result["minTime"]
                )

                maxMinTime = max(maxMinTime, result["minTime"])

                if result["implementation"] not in groups:
                    groups.append(result["implementation"])

            model = t["model"]
            if model in sets:
                n = 2
                while model+" ("+str(n)+")" in sets:
                    n += 1
                model = model+" ("+str(n)+")"

            sets.append((model,datapoints))

        unit = "s"
        if maxMinTime < 0.5e-3:
            unit = "us"
            sets = [ (m, {i: (t*1e6,ep*1e6,em*1e6) for i,(t,ep,em) in r.items()}) for m,r in sets]
        elif maxMinTime < 0.5:
            unit = "ms"
            sets = [ (m, {i: (t*1e3,ep*1e3,em*1e3) for i,(t,ep,em) in r.items()}) for m,r in sets]

        # Plot the data
        self.plotGroupedBarplots(sets, groups, ascendingOrder=False)

        plt.xlabel('Implementación', fontsize=14)
        plt.ylabel('Tiempo', fontsize=14)
        plt.title('Tiempo de ejecucion de '+filterName+' sobre lena.bmp 512x512',
                   fontsize=16)
        plt.gca().yaxis.set_major_formatter(mticker.FormatStrFormatter('%g'+unit))
        plt.legend(loc='best')

        plt.savefig(path+filterName+"_time.png")

    def plotSpeedup(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (speedup, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []
        for host,t in tests.items():
            if filterName+"_implementaciones" not in t["tests"]:
                continue

            datapoints = {}
            base = None

            for result in t["tests"][filterName+"_implementaciones"]["results"]:
                if result["implementation"] == "c":
                    base = result["avgTime"]
                else:
                    datapoints[result["implementation"]] = (
                            result["avgTime"],
                            result["maxTime"],
                            result["minTime"],
                    )

                    if result["implementation"] not in groups:
                        groups.append(result["implementation"])

            # Normalize the data
            datapoints = { i: (base/a,base/ma - base/a,base/a - base/mi) for i,(a,ma,mi) in datapoints.items()}

            model = t["model"]
            if model in sets:
                n = 2
                while model+" ("+str(n)+")" in sets:
                    n += 1
                model = model+" ("+str(n)+")"

            sets.append((model,datapoints))

        # Plot the data
        self.plotGroupedBarplots(sets, groups)

        plt.xlabel('Implementación', fontsize=14)
        plt.ylabel('Speedup', fontsize=14)
        plt.title('Speedup en tiempo relativo a la implementación en C de '+
                  filterName+' sobre lena.bmp 512x512', fontsize=14)
        plt.gca().yaxis.set_major_formatter(mticker.FormatStrFormatter('%gx'))
        plt.legend(loc='best')
        plt.ylim(ymin=0.)

        plt.savefig(path+filterName+"_time_speedup.png");


    # Utils

    def loadTests(self, dataDir):
        tests = {}
        for filename in glob.glob(os.path.join(dataDir, '*.json')):
            name = os.path.splitext(os.path.basename(filename))[0]

            with open(filename, 'r') as f:
                tests[name] = json.load(f)

        return tests

    def getColor(self,model):
        if model not in self.modelColors:
            self.modelColors[model] = self.COLORS[(len(self.modelColors)) % len(self.COLORS)]

        return self.modelColors[model]

    def setupPyplot(self):
        plt.style.use('ggplot')

        fig, ax = plt.subplots()

        # You typically want your plot to be ~1.33x wider than tall.
        plt.figure(figsize=(12, 9))

        return (fig, ax)

    def plotGroupedBarplots(self, sets, groups, ascendingOrder=True):
        # sets: [(label, {group: (value, error+, error-)})]
        # groups: [impl]
        self.setupPyplot()

        # Order the data in a nice ascending order
        order = lambda ss : max(ss) if ascendingOrder else -max(ss)
        groups = sorted(groups, key = lambda g :
                (-len([1 for s in sets if g in s[1]]),
                 order([d[g][0] for l,d in sets if g in d]))
        )

        sets = sorted(sets, key = lambda s : len(s[1]) * 1000 + s[1][groups[0]][0])

        index = np.arange(len(groups))
        bar_width = 0.8 / len(sets)

        for i,s in enumerate(sets):
            model, data = s
            ys = [data[g][0] if g in data else 0 for g in groups]
            yerr = ([data[g][2] if g in data else 0 for g in groups],
                    [data[g][1] if g in data else 0 for g in groups])

            plt.bar(index + bar_width * (i+0.5) - bar_width * (len(sets)) / 2.,
                             ys,
                             bar_width,
                             color = self.getColor(model),
                             label = model,
                             ecolor = (0,0,0),
                             yerr = yerr)

        plt.yticks(fontsize=14)
        plt.xticks(index + bar_width, groups, fontsize=14)


if __name__ == "__main__":
    g = Grapher()
    g.run()

