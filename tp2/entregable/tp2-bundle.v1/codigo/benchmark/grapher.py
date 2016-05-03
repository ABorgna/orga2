#!/usr/bin/env python3

import matplotlib.colors as mplc
import glob
import json
import matplotlib.ticker as mticker
import numpy as np
import os
import matplotlib.pyplot as plt
import random
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

        ########### Test comparing implementations
        implementationPlots = [self.plotTime, self.plotSpeedup, self.plotCycles,
                self.plotCacheMisses, self.plotBranchMisses]

        testNames = ["cropflip", "cropflip-c","sepia","sepia-c","ldr","ldr-c","ldr-precision"]

        [plot(tests,t,GRAPHS_PATH) for plot in implementationPlots for t in testNames]

        ########### Heatmap tests

        cacheMissFn = lambda result : 100 * result["cacheMisses"] / result["cacheReferences"]
        branchMissFn = lambda result : 100 * result["branchMisses"] / result["branches"]
        timeFn = lambda result : result["q2Time"] if result["q2Time"] else 1e-6
        relativeTimeFn = lambda result : (result["size"][0] * result["size"][1]) / (1e6 * result["q2Time"]) \
                if result["q2Time"] != 0 else (result["size"][0] * result["size"][1])

        filtrosImpl = [("ldr","c"),("ldr","sse"),("ldr","avx2"),
                       ("sepia","c"),("sepia","sse"),("sepia","avx2"),
                       ("cropflip","c"),("cropflip","sse"),("cropflip","sse_par"),("cropflip","avx")]

        testImpls = []
        for filtro, impl in filtrosImpl:
            # Filter, implementation, valueFunction, outputName, label, format, logarithmic?
            testImpls += [
                (filtro,impl,cacheMissFn,"cache","Cache misses","%g%%",False),
                (filtro,impl,branchMissFn,"branch","Branch misses","%g%%",False),
                (filtro,impl,timeFn,"time","Tiempo de ejecución","%gs",True),
                (filtro,impl,relativeTimeFn,"time-rel","Millones de pixeles por segundo","%g",False),
            ]

        [self.plotGenericHeatmap(tests,t,i,fn,n,label,f,log,GRAPHS_PATH)
                for t,i,fn,n,label,f,log in testImpls]

        # Precision tests
        self.plotPrecision(tests, "ldr", GRAPHS_PATH)

    # Graphs

    def plotCycles(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (minCycles, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []

        params = None
        size = None

        for host,t in tests.items():
            if filterName+"-implementaciones" not in t["tests"]:
                continue

            datapoints = {}
            base = None

            test = t["tests"][filterName+"-implementaciones"]
            params = test["params"][0]
            size = test["sizes"][0]

            for result in test["results"]:
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
        plt.title(filterName.replace("-c","")+' lena.'+str(size[0])+'x'+str(size[1])+'.bmp '+params, fontsize=14)

        plt.savefig(path+filterName+"-cycles.png")

        plt.close("all")

    def plotCacheMisses(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (minCycles, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []

        params = None
        size = None

        for host,t in tests.items():
            if filterName+"-implementaciones" not in t["tests"]:
                continue

            datapoints = {}

            test = t["tests"][filterName+"-implementaciones"]
            params = test["params"][0]
            size = test["sizes"][0]

            for result in test["results"]:
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
        plt.title(filterName.replace("-c","")+' lena.'+str(size[0])+'x'+str(size[1])+'.bmp '+params, fontsize=14)

        plt.savefig(path+filterName+"-cache-misses.png")

        plt.close("all")

    def plotBranchMisses(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (minCycles, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []

        params = None
        size = None

        for host,t in tests.items():
            if filterName+"-implementaciones" not in t["tests"]:
                continue

            datapoints = {}

            test = t["tests"][filterName+"-implementaciones"]
            params = test["params"][0]
            size = test["sizes"][0]

            for result in test["results"]:
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
        plt.title(filterName.replace("-c","")+' lena.'+str(size[0])+'x'+str(size[1])+'.bmp '+params, fontsize=14)

        plt.savefig(path+filterName+"-branch-misses.png")

        plt.close("all")

    def plotTime(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (minTime, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []
        maxMedianTime = 0.

        params = None
        size = None

        for host,t in tests.items():
            if filterName+"-implementaciones" not in t["tests"]:
                continue

            datapoints = {}
            base = None

            test = t["tests"][filterName+"-implementaciones"]
            params = test["params"][0]
            size = test["sizes"][0]

            for result in test["results"]:
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
        plt.title(filterName.replace("-c","")+' lena.'+str(size[0])+'x'+str(size[1])+'.bmp '+params, fontsize=14)

        plt.savefig(path+filterName+"-time.png")

        plt.close("all")

    def plotSpeedup(self, tests, filterName, path):
        # sets: [(cpuModel, {impl: (speedup, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []

        params = None
        size = None

        for host,t in tests.items():
            if filterName+"-implementaciones" not in t["tests"]:
                continue

            datapoints = {}
            base = None

            test = t["tests"][filterName+"-implementaciones"]
            params = test["params"][0]
            size = test["sizes"][0]

            for result in test["results"]:
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
        plt.title(filterName.replace("-c","")+' lena.'+str(size[0])+'x'+str(size[1])+'.bmp '+params, fontsize=14)
        plt.ylim(ymin=0.)

        plt.savefig(path+filterName+"-time-speedup.png");

        plt.close("all")

    def plotGenericHeatmap(self, tests, filterName, implementation,
                           valueFn, name, barLabel, labelFormat, logarithmic, path):
        # sets: [(cpuModel, {impl: (speedup, error+, error-)})]
        # groups: [impl]
        sets = []
        groups = []

        params = None

        for host,t in tests.items():
            if filterName+"-sizes" not in t["tests"]:
                continue

            model = t["model"]
            test = t["tests"][filterName+"-sizes"]
            params = test["params"][0]

            sizes = test["sizes"]
            widths = list(set([w for w,h in sizes]))
            heights = list(set([h for w,h in sizes]))
            widths.sort()
            heights.sort()

            data = np.zeros((len(heights),len(widths)))

            for result in test["results"]:
                if result["implementation"] != implementation:
                    continue

                size = result["size"]
                x = widths.index(size[0])
                y = heights.index(size[1])
                data[y][x] = valueFn(result)

            # Plot the data
            fig, ax = self.plotHeatmap(data, widths, heights, barLabel, labelFormat, logarithmic)

            plt.xlabel('Ancho en píxeles', fontsize=14)
            plt.ylabel('Alto en píxeles', fontsize=14)
            plt.title(filterName+' -i '+implementation+' lena.WxH.bmp '+params+"\n"+model, fontsize=14)

            plt.savefig(path+filterName+"-"+name+"-map-"+implementation+"-"+host+".png");

            plt.close("all")

    def plotPrecision(self, tests, filterName, path):
        # sets: [(implementation, {image: (maxDiff, 0, 0)})]
        # groups: [impl]
        sets = []
        setDicc = {}
        groups = []

        test = None
        host = None

        for h,t in tests.items():
            if filterName+"-precision" in t["tests"]:
                test = t["tests"][filterName+"-precision"]
                host = h
                break

        if test is None:
            return

        for result in test["results"]:
            impl = result["implementation"]
            img = result["img"]

            if img not in groups:
                groups.append(img)

            if impl not in setDicc:
                setDicc[impl] = {}

            setDicc[impl][img] = (
                    result["maxDiff"],0,0
            )

        sets = setDicc.items()

        # Plot the data
        fig, ax = self.plotGroupedBarplots(sets, groups, ascendingOrder=False)

        plt.xlabel('Imagen', fontsize=14)
        plt.ylabel('Diferencia máxima', fontsize=14)
        plt.gca().yaxis.set_major_formatter(mticker.FormatStrFormatter('%d'))
        plt.legend(loc='best')

        plt.savefig(path+filterName+"-precision.png")

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

    def setupPyplot(self, size=(12,9)):
        plt.style.use('ggplot')

        fig, ax = plt.subplots()

        # You typically want your plot to be ~1.33x wider than tall.
        fig.set_size_inches(size)

        return (fig, ax)

    def plotGroupedBarplots(self, sets, groups, ascendingOrder=True):
        # sets: [(label, {group: (value, error+, error-)})]
        # groups: [impl]
        fig, ax = self.setupPyplot((12,4))

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
                             yerr = yerr if any(yerr[0]) or any(yerr[1]) else None)

        plt.yticks(fontsize=14)
        plt.xticks(index + bar_width, groups, fontsize=14)

        return fig, ax

    def plotHeatmap(self, data, xlabels, ylabels, barLabel, barLabelFormat="%g", logarithmic = False):
        fig, ax = self.setupPyplot((8,6))

        if logarithmic:
            heatmap = ax.pcolor(data, cmap=plt.cm.Blues, norm=mplc.LogNorm())
        else:
            heatmap = ax.pcolor(data, cmap=plt.cm.Blues)

        cbar = plt.colorbar(heatmap, format=mticker.FormatStrFormatter(barLabelFormat),label=barLabel)

        # put the major ticks at the middle of each cell
        ax.set_xticks(np.arange(data.shape[0])+0.5, minor=False)
        ax.set_yticks(np.arange(data.shape[1])+0.5, minor=False)

        ax.set_xticklabels(xlabels, minor=False)
        ax.set_yticklabels(ylabels, minor=False)


        return fig, ax

if __name__ == "__main__":
    g = Grapher()
    g.run()

