#!/usr/bin/env python3
import sys
import os
def main():
    name = sys.argv[1]
    print(name)
    print(os.cpu_count())

main()
