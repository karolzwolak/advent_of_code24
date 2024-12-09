#!/bin/bash
rg "mul\(\d{1,3},\d{1,3}\)|do\(\)|don't\(\)" -o <input3.txt |
    rg "\d{1,3},\d{1,3}|do\(\)|don't\(\)" -o |
    awk 'BEGIN {enabled = 1 } {
    if ($1 == "don'\''t()") enabled = 0;
    else if ($1 == "do()") enabled = 1;
    else if (enabled == 1) print $1}' |
    awk -F, '{print $1 * $2}' |
    awk '{sum += $1} END {print sum}'
