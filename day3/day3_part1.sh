#!/bin/bash
rg "mul\(\d{1,3},\d{1,3}\)" -o <input3.txt | rg "\d{1,3},\d{1,3}" -o | awk -F, '{print $1 * $2}' | awk '{sum += $1} END {print sum}'
