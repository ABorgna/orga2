#!/usr/bin/env python3

import json
import os
import re
import shutil
import subprocess
import sys

HELP = """Usage: ./benchmark.py test [test ...]

Where test is one of:
        all
"""     # TESTS

TP2_BIN = "../build/tp2"
BMPDIFF = "../build/bmpdiff"
PERF = "perf"

GEN_PATH = "gen/"
IMG_OUT_PATH = "out/"
DATA_OUT_PATH = "data/"

TIME_PER_TEST = 1.0

TESTS = {
    "cropflip-implementaciones": {
        "filter": "cropflip",
        "imgs": ["img/lena.bmp"],
        "implementations": ["c_O3", "sse","sse_par","avx"],
        "sizes": [(512,512)],
        "params": ["128 128 128 128"]
    },
    "cropflip-c-implementaciones": {
        "filter": "cropflip",
        "imgs": ["img/lena.bmp"],
        "implementations": ["c_O0","c_O1", "c_O2", "c_O3"],
        "sizes": [(512,512)],
        "params": ["128 128 128 128"]
    },
    "sepia-implementaciones": {
        "filter": "sepia",
        "imgs": ["img/lena.bmp"],
        "implementations": ["c","sse","avx2"],
        "sizes": [(512,512)],
        "params": [""]
    },
    "sepia-c-implementaciones": {
        "filter": "sepia",
        "imgs": ["img/lena.bmp"],
        "implementations": ["c_O0","c_O1", "c_O2", "c_O3"],
        "sizes": [(512,512)],
        "params": [""]
    },
    "ldr-implementaciones": {
        "filter": "ldr",
        "imgs": ["img/lena.bmp"],
        "implementations": ["c","sse","avx","avx2"],
        "sizes": [(512,512)],
        "params": ["100"]
    },
    "ldr-c-implementaciones": {
        "filter": "ldr",
        "imgs": ["img/lena.bmp"],
        "implementations": ["c_O0","c_O1", "c_O2", "c_O3"],
        "sizes": [(512,512)],
        "params": ["100"]
    },
    "ldr-sizes": {
        "filter": "ldr",
        "imgs": ["img/lena.bmp"],
        "implementations": ["sse"],
        "sizes": [(2**w,2**h) for w in range(7, 13) for h in range(7,13)],
        "params": ["100"]
    },
    "ldr-precision": {
        "filter": "ldr",
        "imgs": ["img/lena.bmp","img/12d9xx.jpg","img/18ifgk.jpg","img/15979a.jpg",
                 "img/colores32.bmp","img/fine.png"],
        "implementations": ["sse","sse_integer"],
        "sizes": [(0,0)],               # (0,0) == original size
        "params": ["255"],
        "singleRun": True,              # Optional, defaults to False
        "referenceImplementation": "c"  # Optional, will generate "maxDiff" if not None
    }
}

for t in TESTS:
    HELP += "        "+t+"\n"

class Benchmark:

    # Regexes matching the output of the script

    completedRe = re.compile(r"^\s*Tiempo de ejecución",re.M)
    iterationsRe = re.compile(r"^\s*# iteraciones\s+: ([0-9]+)",re.M)

    cyclesRe = re.compile(r"^\s*# de ciclos insumidos por llamada\s+: ([0-9.]+)",re.M)
    minCyclesRe = re.compile(r"^\s*# minimo de ciclos insumidos\s+: ([0-9.]+)",re.M)
    maxCyclesRe = re.compile(r"^\s*# maximo de ciclos insumidos\s+: ([0-9.]+)",re.M)
    q1CyclesRe  = re.compile(r"^\s*# de ciclos q1\s+: ([0-9.]+)",re.M)
    q2CyclesRe  = re.compile(r"^\s*# de ciclos q2\s+: ([0-9.]+)",re.M)
    q3CyclesRe  = re.compile(r"^\s*# de ciclos q3\s+: ([0-9.]+)",re.M)
    p10CyclesRe = re.compile(r"^\s*# de ciclos p10\s+: ([0-9.]+)",re.M)
    p90CyclesRe = re.compile(r"^\s*# de ciclos p90\s+: ([0-9.]+)",re.M)

    timeRe = re.compile(r"^\s*tiempo total\s+: ([0-9.]+)",re.M)
    minTimeRe = re.compile(r"^\s*tiempo minimo\s+: ([0-9.]+)",re.M)
    maxTimeRe = re.compile(r"^\s*tiempo maximo\s+: ([0-9.]+)",re.M)
    q1TimeRe  = re.compile(r"^\s*tiempo q1\s+: ([0-9.]+)",re.M)
    q2TimeRe  = re.compile(r"^\s*tiempo q2\s+: ([0-9.]+)",re.M)
    q3TimeRe  = re.compile(r"^\s*tiempo q3\s+: ([0-9.]+)",re.M)
    p10TimeRe = re.compile(r"^\s*tiempo p10\s+: ([0-9.]+)",re.M)
    p90TimeRe = re.compile(r"^\s*tiempo p90\s+: ([0-9.]+)",re.M)

    perfCacheRefRe = re.compile(r"^\s*([0-9,.]+)\s+cache-references",re.M)
    perfCacheMissRe = re.compile(r"^\s*([0-9,.]+)\s+cache-misses",re.M)
    perfBranchesRe = re.compile(r"^\s*([0-9,.]+)\s+branches",re.M)
    perfBranchMissRe = re.compile(r"^\s*([0-9,.]+)\s+branch-misses",re.M)
    perfFaultsRe = re.compile(r"^\s*([0-9,.]+)\s+faults",re.M)

    invalidInstructionRe = re.compile(r"^Command terminated by signal 4",re.M)

    cpuinfoModelRe = re.compile(r"^model name\s*:\s(.*)$",re.M)


    def __init__(self):
        self.unsuportedImplementations = []
        self.__cpuinfo = None

    def run(self,tests):
        testCount = self.countTests(tests)
        current = 1

        print("Running ",testCount, " tests (~"+str(TIME_PER_TEST*testCount*1.5)+"s)")

        if not os.path.exists(IMG_OUT_PATH):
            os.makedirs(IMG_OUT_PATH)

        for testName, test in tests.items():
            results = []
            print("----",testName,"----")

            for img in test["imgs"]:
                for size in test["sizes"]:

                    if size == (0,0):
                        # Original size
                        size = self.getImageSize(img)

                    # Image width must be a multiple of 8
                    size = (size[0] - size[0] % 8, size[1])

                    resizedImg = self.generateTestImage(img,size)

                    for param in test["params"]:

                        if test.get("referenceImplementation", None) is not None:
                            self.runTest(resizedImg,test["filter"],test["referenceImplementation"],
                                         param, singleRun=True)

                        for implementation in test["implementations"]:
                            if implementation in self.unsuportedImplementations:
                                continue

                            print(str(current)+"/"+str(testCount),"-",
                                    test["filter"]+":"+implementation,
                                    "("+param+")" if len(param.strip()) else "",
                                    img, str(size[0])+"x"+str(size[1]))

                            result = self.runTest(resizedImg,test["filter"],
                                                  implementation, param,
                                                  minTime=TIME_PER_TEST,
                                                  singleRun=test.get("singleRun",False),
                                                  referenceImplementation=
                                                        test.get("referenceImplementation", None))
                            if result is None:
                                print("Error :(")
                            else:
                                result["size"] = size
                                result["img"] = img
                                result["param"] = param
                                result["implementation"] = implementation
                                results.append(result)

                            current += 1

            tests[testName]["results"] = results

        outfile = DATA_OUT_PATH + self.getHostname() + ".json"
        outputData = {
                "hostname": self.getHostname(),
                "cpuinfo": self.getCpuinfo(),
                "model": self.getCpuModel(),
                "tests": tests
        }

        outputData = self.mergeOldTests(outputData, outfile)

        if not os.path.exists(DATA_OUT_PATH):
            os.makedirs(DATA_OUT_PATH)

        with open(outfile, 'w+') as f:
            json.dump(outputData,f)

    def countTests(self,tests):
        count = 0
        for testName, test in tests.items():
            count += len(test["sizes"]) * len(test["implementations"]) \
                   * len(test["imgs"]) * len(test["params"])
        return count

    def generateTestImage(self,source,size):
        sizeStr = str(size[0]) + "x" + str(size[1])
        sourceName = os.path.basename(source)
        filename = sourceName + "." + sizeStr  + ".bmp"
        path = GEN_PATH + filename

        if not os.path.exists(GEN_PATH):
            os.makedirs(GEN_PATH)

        if not os.path.exists(path):
            arguments = ["/usr/bin/env","convert",source,
                         "-resize",sizeStr+r"!",
                         "-colorspace","rgb",
                         "-type","TrueColor",
                         "-channel","rgb",
                         "-depth","8",
                         "-alpha","on",
                         "-compress","none",
                         "BMP3:"+str(path)]
            subprocess.check_call(arguments)

        return path

    def getImageSize(self,img):
        widthArguments = ["/usr/bin/env", "identify",
                          "-format","%w", img]
        heightArguments = ["/usr/bin/env", "identify",
                          "-format","%h", img]
        width = int(subprocess.check_output(widthArguments))
        height = int(subprocess.check_output(heightArguments))
        return (width,height)

    def runTest(self, img, filterName, implementation, *args,
            minTime = 2.0, minIterations=100, singleRun=False,
            referenceImplementation=None):

        hasPerf = True if shutil.which(PERF) is not None else False
        perfOptions = "cache-references,cache-misses,branches,branch-misses,faults"

        if hasPerf:
            arguments = [PERF, "stat", "-e", perfOptions, TP2_BIN, filterName,
                            "-t", minIterations,
                            "-o", IMG_OUT_PATH,
                            "-i", implementation,
                            img, "--"] + [e for a in args for e in a.split()]
            iterationsIndex = 7
        else:
            arguments = [TP2_BIN, filterName,
                            "-t", minIterations,
                            "-o", IMG_OUT_PATH,
                            "-i", implementation,
                            img, "--"] + [e for a in args for e in a.split()]
            iterationsIndex = 3
        arguments = [str(a) for a in arguments]

        first = True
        totalTime = 0
        iterations = 1 if singleRun else minIterations
        while first or (totalTime < minTime and not singleRun):
            if not first:
                if iterations > 1000000 and \
                    (not totalTime or iterations / totalTime < 10000):
                    print("Over a million iterations and no time spent.",
                          "Aborting.")
                    return None

                if totalTime < 0.01:
                    iterations *= 10
                else:
                    calcIts = int(1.1 * iterations * minTime / totalTime)
                    if iterations < calcIts:
                        iterations = calcIts
                    else:
                        iterations *= 10

                arguments[iterationsIndex] = str(iterations)
            else:
                first = False

            try:
                out = subprocess.check_output(arguments,
                                              stderr=subprocess.STDOUT,
                                              universal_newlines=True,
                                              env=self.getEnglishEnvironment())
            except subprocess.CalledProcessError as e:
                if self.invalidInstructionRe.search(e.output):
                    if not implementation in self.unsuportedImplementations:
                        print(implementation,"won't run in this processor!")
                        self.unsuportedImplementations.append(implementation)
                    return None

                print("Error!")
                print("Output: ",e.output)
                print("err: ",e.stderr)
                return None

            # Return if the process failed
            if not self.completedRe.search(out):
                return None

            totalTime = float(self.timeRe.search(out).group(1))

        # Parse the output data
        iterations = int(float(self.iterationsRe.search(out).group(1)))
        totalCycles = int(float(self.cyclesRe.search(out).group(1)))

        # Calculate the maximum pixel diff
        maxDiff = None
        if referenceImplementation is not None:
            outImage = IMG_OUT_PATH+os.path.basename(img)+"." \
                +filterName+"."+implementation.upper()+".bmp"
            referenceImage = IMG_OUT_PATH+os.path.basename(img)+"." \
                +filterName+"."+referenceImplementation.upper()+".bmp"

            maxDiff = self.getMaxPixelDiff(referenceImage,outImage)

        return {
            "iterations": iterations,

            "totalCycles": totalCycles,
            "minCycles": int(float(self.minCyclesRe.search(out).group(1))),
            "maxCycles": int(float(self.maxCyclesRe.search(out).group(1))),
            "q1Cycles" : int(float(self.q1CyclesRe.search(out).group(1))),
            "q2Cycles" : int(float(self.q2CyclesRe.search(out).group(1))),
            "q3Cycles" : int(float(self.q3CyclesRe.search(out).group(1))),
            "p10Cycles": int(float(self.p10CyclesRe.search(out).group(1))),
            "p90Cycles": int(float(self.p90CyclesRe.search(out).group(1))),
            "avgCycles": int(totalCycles / iterations),

            "totalTime": totalTime,
            "minTime": float(self.minTimeRe.search(out).group(1)),
            "maxTime": float(self.maxTimeRe.search(out).group(1)),
            "q1Time" : float(self.q1TimeRe.search(out).group(1)),
            "q2Time" : float(self.q2TimeRe.search(out).group(1)),
            "q3Time" : float(self.q3TimeRe.search(out).group(1)),
            "p10Time": float(self.p10TimeRe.search(out).group(1)),
            "p90Time": float(self.p90TimeRe.search(out).group(1)),
            "avgTime": totalTime / iterations,

            "maxDiff": maxDiff,

            "cacheReferences": int(self.perfCacheRefRe.search(out).group(1)
                               .replace(",","").replace(".","")) \
                    if hasPerf else None,
            "cacheMisses": int(self.perfCacheMissRe.search(out).group(1)
                               .replace(",","").replace(".","")) \
                    if hasPerf else None,
            "branches": int(self.perfBranchesRe.search(out).group(1)
                               .replace(",","").replace(".","")) \
                    if hasPerf else None,
            "branchMisses": int(self.perfBranchMissRe.search(out).group(1)
                               .replace(",","").replace(".","")) \
                    if hasPerf else None,
            "faults": int(self.perfFaultsRe.search(out).group(1)
                               .replace(",","").replace(".","")) \
                    if hasPerf else None,
        }

    def getMaxPixelDiff(self, baseImg, targetImg):
        return max(self.getPixelDiffs(baseImg, targetImg), key=int, default=0)

    def getPixelDiffs(self, baseImg, targetImg):
        arguments = [BMPDIFF, "-s", baseImg, targetImg, "0"]
        output = ""
        try:
            output = subprocess.check_output(arguments).decode("utf-8")
        except subprocess.CalledProcessError as e:
            # bmpdiff returns 255 if there are differences
            output = e.output.decode("utf-8")

        return { int(l.split()[0]) : int(l.split()[1]) for l in output.split('\n') if len(l.split()) == 2}

    def getHostname(self):
        return subprocess.check_output(["cat","/etc/hostname"]).decode("utf-8").strip()

    def getCpuinfo(self):
        if self.__cpuinfo is None:
            self.__cpuinfo = subprocess.check_output(["cat","/proc/cpuinfo"]).decode("utf-8").strip()
        return self.__cpuinfo

    def getCpuModel(self):
        return self.cpuinfoModelRe.search(self.getCpuinfo()).group(1)

    def mergeOldTests(self, outputData, outfile):
        if os.path.exists(outfile):
            with open(outfile, 'r') as f:
                oldData  = json.load(f)

            for t,d in oldData["tests"].items():
                if t not in outputData["tests"]:
                    outputData["tests"][t] = d

        return outputData

    def getEnglishEnvironment(self):
        env = os.environ.copy()

        env["LANG"] = "en_US.UTF-8"
        env["LANGUAGE"] = ""
        env["LC_CTYPE"] = "en_US.UTF-8"
        env["LC_NUMERIC"] = "en_US.UTF-8"
        env["LC_TIME"] = "en_US.UTF-8"
        env["LC_COLLATE"] = "en_US.UTF-8"
        env["LC_MONETARY"] = "en_US.UTF-8"
        env["LC_MESSAGES"] = "en_US.UTF-8"
        env["LC_PAPER"] = "en_US.UTF-8"
        env["LC_NAME"] = "en_US.UTF-8"
        env["LC_ADDRESS"] = "en_US.UTF-8"
        env["LC_TELEPHONE"] = "en_US.UTF-8"
        env["LC_MEASUREMENT"] = "en_US.UTF-8"
        env["LC_IDENTIFICATION"] = "en_US.UTF-8"
        env["LC_ALL"] = ""

        return env

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(HELP)
        sys.exit(1)

    test = sys.argv[1]
    tests = {}

    for i in range(1, len(sys.argv)):
        t = sys.argv[i]

        if t == "all":
            tests = TESTS
            break

        elif t in TESTS:
            tests[t] = TESTS[t]

        else:
            print("Test",t,"not found.")
            print()
            print(HELP)
            sys.exit(2)

    bench = Benchmark()
    bench.run(tests)

