#!/usr/bin/env python3

import subprocess

arguments = ['time', './tp2catedra', 'cropflip', '-t', '100000000',
             '-i', 'c', './lena32.bmp', '--', '128 128 128 128']

subprocess.check_call(arguments)

