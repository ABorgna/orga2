#!/usr/bin/env python3

import json
import os
import re
import subprocess

TESTS = [
    {   "filterName": "ldr",
        "img": "bench/img/lena.bmp",
        "implementations": ["c","sse","sse_float","avx","avx2"],
        #"sizes": [(256,128),(256,196),(256,256),(256,512),(256,1024),(256,2048),(256,4096)],
        "sizes": [(256,128),(256,512)],
        "params": "100"
    }
]

class Benchmark:

    TIME = "/usr/bin/env time"
    BINARY_PATH = "../build/tp2"
    GEN_PATH = "bench/gen/"
    IMG_OUT_PATH = "bench/out/"
    OUT_FILE = "bench.json"

    TIME_PER_TEST = 2.0

    # Regexes matching the output of the script

    realTimeRe = re.compile(r"^real ([0-9.]+)",re.M)
    userTimeRe = re.compile(r"^user ([0-9.]+)",re.M)
    sysTimeRe = re.compile(r"^sys ([0-9.]+)",re.M)
    completedRe = re.compile(r"^\s*Tiempo de ejecución",re.M)
    iterationsRe = re.compile(r"^\s*# iteraciones\s+: ([0-9]+)",re.M)
    cyclesRe = re.compile(r"^\s*# de ciclos insumidos por llamada\s+: ([0-9.]+)",re.M)


    def __init__(self):
        pass

    def run(self,tests):
        testCount = self.countTests(tests)
        current = 1

        print("Running ",testCount, " tests (~"+str(self.TIME_PER_TEST*testCount*1.5)+"s)")

        for testI, test in enumerate(tests):
            results = []
            for size in test["sizes"]:
                resizedImg = self.generateTestImage(test["img"],size)
                for implementation in test["implementations"]:
                    print(str(current)+"/"+str(testCount),"-",
                            test["filterName"]+":"+implementation,
                            test["img"],str(size[0])+"x"+str(size[1]))

                    result = self.runTest(resizedImg,test["filterName"],
                                          implementation, test["params"],
                                          minTime=self.TIME_PER_TEST)
                    if result is None:
                        print("Error :(")
                    else:
                        result["size"] = size
                        result["implementation"] = implementation
                        results.append(result)

                    current += 1

            tests[testI]["results"] = results

        with open(self.OUT_FILE, 'w') as f:
            json.dump(tests,f)

    def countTests(self,tests):
        count = 0
        for test in tests:
            count += len(test["sizes"]) * len(test["implementations"])
        return count

    def generateTestImage(self,source,size):
        sizeStr = str(size[0]) + "x" + str(size[1])
        sourceName = os.path.basename(source)
        filename = sourceName + "." + sizeStr  + ".bmp"
        path = self.GEN_PATH + filename

        if not os.path.exists(self.GEN_PATH):
            os.makedirs(self.GEN_PATH)

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
            process = subprocess.run(arguments)

        return path

    def runTest(self, img, filterName, implementation, *args,
            minTime = 2.0, minIterations=100):

        # Use time
        arguments = ["/usr/bin/env", "time", "-p", self.BINARY_PATH, filterName,
                     "-t", minIterations, "-o", self.IMG_OUT_PATH,
                     "-i", implementation, img, "--"] + list(args)
        arguments = [str(s) for s in arguments]

        first = True
        userTime = 0
        iterations = minIterations
        while userTime < minTime:
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


            process = subprocess.run(arguments, stdout=subprocess.PIPE,
                                     stderr=subprocess.PIPE, universal_newlines=True)
            out = process.stderr + process.stdout

            userTime = float(self.userTimeRe.search(out).group(1))

            # Return if the process failed
            if not self.completedRe.search(out):
                return None

        # Parse the output data
        iterations = int(float(self.iterationsRe.search(out).group(1)))
        cycles = int(float(self.cyclesRe.search(out).group(1)))
        time = userTime/iterations

        return {
            "totalTime": userTime,
            "time": time,
            "iterations": iterations,
            "cycles": cycles
        }

if __name__ == "__main__":
    bench = Benchmark()
    bench.run(TESTS)

