#!/usr/bin/env python

import re

HELP = """A simple midi-to-custom-format converter

Usage: ./frommidi.py input.midi output_#.audio

Converts only channel #
"""

import sys
import numpy as np
from mido import MidiFile

class Convert:

    def frommidi(self, infile, outfile, channel=0):
        self.timeOffsets = {}

        outArray = []

        for m in MidiFile(infile).play():
            if m.type == 'note_on' and m.channel == channel:
                outArray = \
                    self.addMidiNote(outArray, m.time, m.note, m.velocity)

            if m.type == 'note_off' and m.channel == channel:
                outArray = \
                    self.addMidiNote(outArray, m.time, 0, 0)

        self.writeFile(outArray, outfile)

    def addMidiNote(self, array, time, note, velocity=127):
        if(velocity == 0):
            note = 0

        millis = (int) (time*1000)

        while len(array) and millis >= 256:
            array[-1] = 255
            array += [array[-2], 1]
            millis -= 255

        if len(array):
            array[-1] = millis

        return array + [note, 1]

    def noteToFreq(self, note):
        return 440 * (2**((note - 69)/12))

    def writeFile(self, array, outfile):
        narray = np.array(array, dtype=np.uint8)
        narray.astype('uint8').tofile(outfile)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(HELP)
        sys.exit(1)

    infile = sys.argv[1]
    outfile = sys.argv[2]

    channel = 0
    channelMatch = re.match(r".*_([0-9]+)\.audio", outfile)
    if channelMatch is not None:
        channel = (int) (channelMatch.group(1))

    print("Converting", infile, "channel", channel, "to AUDIO format")

    convert = Convert()
    convert.frommidi(infile, outfile, channel)

