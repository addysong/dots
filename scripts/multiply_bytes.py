#!/usr/bin/env python3

from sys import argv

if len(argv) < 2:
    print("Not enough arguments")
    exit(1)

input = argv[1]
if len(argv[1]) % 2 == 1:
    print("Invalid number of bytes")

mult = float(argv[2])

num_bytes = int(len(argv[1]) / 2)
bytes_array = [input[i*2] + input[i*2+1] for i in range(num_bytes)]
bytes_array = [hex(int(int(b, 16) * mult))[2:] for b in bytes_array]

print(' '.join(bytes_array))
