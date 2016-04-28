#!/usr/bin/env python3

import json
import os
import re
import subprocess
import sys

TIME = "/usr/bin/env time"
TP2_BIN = "../build/tp2"
BMPDIFF = "../build/bmpdiff"

GEN_PATH = "gen/"
IMG_OUT_PATH = "out/"
DATA_OUT_PATH = "data/"

TIME_PER_TEST = 1.0

# Checkear que todos los anchos sean multiplos de 8, sino explota todo
TESTS = {
    "ldr_implementaciones": {
        "filter": "ldr",
        "imgs": ["img/lena.bmp"],
        "implementations": ["c","sse","avx","avx2"],
        "sizes": [(512,512)],
        "params": ["100"],
        "singleRun": True
    },
    "ldr_precision": {
        "filter": "ldr",
        "imgs": ["img/lena.bmp"],
        "implementations": ["sse","sse_integer"],
        "sizes": [(512,512)],
        "params": ["100","255","-255"],
        "singleRun": True,              # Optional, defaults to False
        "referenceImplementation": "c"  # Optional, will generate "maxDiff" if not None
    }
}

class Benchmark:

    # Regexes matching the output of the script

    realTimeRe = re.compile(r"^real ([0-9.]+)",re.M)
    userTimeRe = re.compile(r"^user ([0-9.]+)",re.M)
    sysTimeRe = re.compile(r"^sys ([0-9.]+)",re.M)
    completedRe = re.compile(r"^\s*Tiempo de ejecución",re.M)
    iterationsRe = re.compile(r"^\s*# iteraciones\s+: ([0-9]+)",re.M)
    cyclesRe = re.compile(r"^\s*# de ciclos insumidos por llamada\s+: ([0-9.]+)",re.M)
    minCyclesRe = re.compile(r"^\s*# minimo de ciclos insumidos \s+: ([0-9.]+)",re.M)
    invalidInstructionRe = re.compile(r"^Command terminated by signal 4",re.M)


    def __init__(self):
        self.unsuportedImplementations = []

    def run(self,tests):
        testCount = self.countTests(tests)
        current = 1

        print("Running ",testCount, " tests (~"+str(TIME_PER_TEST*testCount*1.5)+"s)")

        for testName, test in tests.items():
            results = []
            print("----",testName,"----")
            for size in test["sizes"]:
                if size[0] % 8:
                    print("Invalid size",str(size[0]) + "x" + str(size[1]),
                          ". Width must be a multiple of 8")
                    continue

                for img in test["imgs"]:
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
                                                  implementation, test["params"],
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
                "tests": tests
        }

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

    def runTest(self, img, filterName, implementation, *args,
            minTime = 2.0, minIterations=100, singleRun=False,
            referenceImplementation=None):

        # Use time
        arguments = ["/usr/bin/env", "time", "-p", TP2_BIN, filterName,
                     "-t", minIterations, "-o", IMG_OUT_PATH,
                     "-i", implementation, img, "--"] + list(args)
        arguments = [str(s) for s in arguments]

        first = True
        userTime = 0
        iterations = 1 if singleRun else minIterations
        while first or (userTime < minTime and not singleRun):
            if not first:
                if userTime < 0.01:
                    iterations *= 100
                else:
                    calcIts = int(minIterations * minTime / userTime)
                    if iterations < calcIts:
                        iterations = calcIts
                    else:
                        iterations *= 10

                arguments[6] = str(iterations)
            else:
                first = False

            try:
                out = subprocess.check_output(arguments, stderr=subprocess.STDOUT,
                                              universal_newlines=True)
            except subprocess.CalledProcessError as e:
                if self.invalidInstructionRe.search(e.output):
                    if not implementation in self.unsuportedImplementations:
                        print(implementation,"won't run in this processor!")
                        self.unsuportedImplementations.append(implementation)
                    return None

                print("Error!")
                print("Output: ",e.output)
                raise

            userTime = float(self.userTimeRe.search(out).group(1))

            # Return if the process failed
            if not self.completedRe.search(out):
                return None

        # Parse the output data
        iterations = int(float(self.iterationsRe.search(out).group(1)))
        cycles = int(float(self.cyclesRe.search(out).group(1)))
        minCycles = int(float(self.cyclesRe.search(out).group(1)))
        time = userTime/iterations

        # Calculate the maximum pixel diff
        maxDiff = -1
        if referenceImplementation is not None:
            outImage = IMG_OUT_PATH+os.path.basename(img)+"." \
                +filterName+"."+implementation.upper()+".bmp"
            referenceImage = IMG_OUT_PATH+os.path.basename(img)+"." \
                +filterName+"."+referenceImplementation.upper()+".bmp"

            maxDiff = self.getMaxPixelDiff(referenceImage,outImage)

        return {
            "totalTime": userTime,
            "time": time,
            "iterations": iterations,
            "cycles": cycles,
            "minCycles": minCycles,
            "maxDiff": maxDiff
        }

    def getMaxPixelDiff(self, baseImg, targetImg):
        return max(self.getPixelDiffs(baseImg, targetImg), key=int)

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
        return subprocess.check_output(["cat","/proc/cpuinfo"]).decode("utf-8").strip()

if __name__ == "__main__":
    if len(sys.argv) != 1:
        print("Usage: ./benchmark.py")
        sys.exit(1)

    bench = Benchmark()
    bench.run(TESTS)

