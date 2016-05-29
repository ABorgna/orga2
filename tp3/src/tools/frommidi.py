#!/usr/bin/env python3

HELP = """A simple midi-to-custom-format converter

Usage: ./frommidi.py input.midi output.audio
"""

import sys
import numpy as np
from mido import MidiFile

class Convert:

    def frommidi(self, infile, outfile, channel=0):

        outArray = []

        for m in MidiFile(infile).play():
            if m.type == 'note_on' and m.channel == channel:
                outArray = self.addMidiNote(outArray, m.time, m.note, m.velocity)

            if m.type == 'note_off' and m.channel == channel:
                outArray = self.addMidiSilence(outArray, m.time)

        self.writeFile(outArray, outfile)

    def addMidiNote(self, array, time, note, velocity=127):
        if(velocity == 0):
            return self.addMidiSilence(array, time)
        else:
            if len(array):
                array[-1] = (int) (time*10000)

            return array + [self.noteToFreq(note), 1]

    def addMidiSilence(self, array, time):
        if len(array):
            array[-1] = (int) (time*10000)
        return array + [0, 1]

    def noteToFreq(self, note):
        return 440 * (2**((note - 69)/12))

    def writeFile(self, array, outfile):
        narray = np.array(array, dtype=np.uint16)
        narray.astype('uint16').tofile(outfile)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(HELP)
        sys.exit(1)

    infile = sys.argv[1]
    outfile = sys.argv[2]

    print("Converting", infile, "to AUDIO format")

    convert = Convert()
    convert.frommidi(infile, outfile)

