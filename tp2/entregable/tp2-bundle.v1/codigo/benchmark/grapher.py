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

        plots = [self.plotTime, self.plotSpeedup, self.plotCycles,
                self.plotCacheMisses, self.plotBranchMisses]

        testNames = ["cropflip", "cropflip-c","sepia","sepia-c","ldr","ldr-c"]

        [plot(tests,t,GRAPHS_PATH) for plot in plots for t in testNames]

    # Graphs

    def plotCycles(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (minCycles, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []

        for host,t in tests.items():
            if filterName+"-implementaciones" not in t["tests"]:
                continue

            datapoints = {}
            base = None

            for result in t["tests"][filterName+"-implementaciones"]["results"]:
                datapoints[result["implementation"]] = (
                        result["q2Cycles"],
                        result["p90Cycles"] - result["q2Cycles"],
                        result["q2Cycles"] - result["p10Cycles"]
                )

                if result["implementation"] not in groups:
                    groups.append(result["implementation"])

            model = t["model"]
            if model in sets:
                n = 2
                while model+" ("+str(n)+")" in sets:
                    n += 1
                model = model+" ("+str(n)+")"

            sets.append((model,datapoints))

        # Plot the data
        fig, ax = self.plotGroupedBarplots(sets, groups, ascendingOrder=False)

        plt.xlabel('Implementación', fontsize=14)
        plt.ylabel('Ciclos de clock', fontsize=14)
        plt.gca().yaxis.set_major_formatter(mticker.FormatStrFormatter('%g'))
        plt.legend(loc='best')

        plt.savefig(path+filterName+"-cycles.png")

        plt.close("all")

    def plotCacheMisses(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (minCycles, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []

        for host,t in tests.items():
            if filterName+"-implementaciones" not in t["tests"]:
                continue

            datapoints = {}

            for result in t["tests"][filterName+"-implementaciones"]["results"]:
                datapoints[result["implementation"]] = (
                        100 * result["cacheMisses"] / result["cacheReferences"],
                        0, 0
                )

                if result["implementation"] not in groups:
                    groups.append(result["implementation"])

            model = t["model"]
            if model in sets:
                n = 2
                while model+" ("+str(n)+")" in sets:
                    n += 1
                model = model+" ("+str(n)+")"

            sets.append((model,datapoints))

        # Plot the data
        fig, ax = self.plotGroupedBarplots(sets, groups, ascendingOrder=False)

        plt.xlabel('Implementación', fontsize=14)
        plt.ylabel('Porcentaje de misses a la cache', fontsize=14)
        plt.gca().yaxis.set_major_formatter(mticker.FormatStrFormatter('%g%%'))
        plt.legend(loc='best')

        plt.savefig(path+filterName+"-cache-misses.png")

        plt.close("all")

    def plotBranchMisses(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (minCycles, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []

        for host,t in tests.items():
            if filterName+"-implementaciones" not in t["tests"]:
                continue

            datapoints = {}

            for result in t["tests"][filterName+"-implementaciones"]["results"]:
                datapoints[result["implementation"]] = (
                        100 * result["branchMisses"] / result["branches"],
                        0, 0
                )

                if result["implementation"] not in groups:
                    groups.append(result["implementation"])

            model = t["model"]
            if model in sets:
                n = 2
                while model+" ("+str(n)+")" in sets:
                    n += 1
                model = model+" ("+str(n)+")"

            sets.append((model,datapoints))

        # Plot the data
        fig, ax = self.plotGroupedBarplots(sets, groups, ascendingOrder=False)

        plt.xlabel('Implementación', fontsize=14)
        plt.ylabel('Porcentaje de branch misspredictions', fontsize=14)
        plt.gca().yaxis.set_major_formatter(mticker.FormatStrFormatter(r'%g%%'))
        plt.legend(loc='best')

        plt.savefig(path+filterName+"-branch-misses.png")

        plt.close("all")

    def plotTime(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (minTime, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []
        maxMedianTime = 0.

        for host,t in tests.items():
            if filterName+"-implementaciones" not in t["tests"]:
                continue

            datapoints = {}
            base = None

            for result in t["tests"][filterName+"-implementaciones"]["results"]:
                datapoints[result["implementation"]] = (
                        result["q2Time"],
                        result["p90Time"] - result["q2Time"],
                        result["q2Time"] - result["p10Time"]
                )

                maxMedianTime = max(maxMedianTime, result["q2Time"])

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
        if maxMedianTime < 0.5e-3:
            unit = "us"
            sets = [ (m, {i: (t*1e6,ep*1e6,em*1e6) for i,(t,ep,em) in r.items()}) for m,r in sets]
        elif maxMedianTime < 0.5:
            unit = "ms"
            sets = [ (m, {i: (t*1e3,ep*1e3,em*1e3) for i,(t,ep,em) in r.items()}) for m,r in sets]

        # Plot the data
        fig, ax = self.plotGroupedBarplots(sets, groups, ascendingOrder=False)

        plt.xlabel('Implementación', fontsize=14)
        plt.ylabel('Tiempo', fontsize=14)
        plt.gca().yaxis.set_major_formatter(mticker.FormatStrFormatter('%g'+unit))
        plt.legend(loc='best')

        plt.savefig(path+filterName+"-time.png")

        plt.close("all")

    def plotSpeedup(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (speedup, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []
        for host,t in tests.items():
            if filterName+"-implementaciones" not in t["tests"]:
                continue

            datapoints = {}
            base = None

            for result in t["tests"][filterName+"-implementaciones"]["results"]:
                if result["implementation"] == "c" or result["implementation"] == "c_O3":
                    base = result["q2Time"]
                else:
                    datapoints[result["implementation"]] = (
                            result["q2Time"],
                            result["p90Time"],
                            result["p10Time"],
                    )

                    if result["implementation"] not in groups:
                        groups.append(result["implementation"])

            # Normalize the data
            div = lambda x, y : x / y if y != 0 else 0
            datapoints = { i: (div(base,a),div(base,ma) - div(base,a),div(base,a) - div(base,mi))
                    for i,(a,ma,mi) in datapoints.items()}

            model = t["model"]
            if model in sets:
                n = 2
                while model+" ("+str(n)+")" in sets:
                    n += 1
                model = model+" ("+str(n)+")"

            sets.append((model,datapoints))

        # Plot the data
        fig, ax = self.plotGroupedBarplots(sets, groups)

        plt.xlabel('Implementación', fontsize=14)
        plt.ylabel('Speedup', fontsize=14)
        plt.gca().yaxis.set_major_formatter(mticker.FormatStrFormatter('%gx'))
        plt.legend(loc='best')
        plt.ylim(ymin=0.)

        plt.savefig(path+filterName+"-time-speedup.png");

        plt.close("all")


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
        plt.figure(figsize=(8, 6))

        return (fig, ax)

    def plotGroupedBarplots(self, sets, groups, ascendingOrder=True):
        # sets: [(label, {group: (value, error+, error-)})]
        # groups: [impl]
        fig, ax = self.setupPyplot()

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

        return fig, ax


if __name__ == "__main__":
    g = Grapher()
    g.run()

