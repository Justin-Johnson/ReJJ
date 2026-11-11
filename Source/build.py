#!/usr/bin/env python3
"""
Builds ReEQ2's two generated includes from their readable sources.

  Source/ReEQ2/analog-fast.jsfx-inc  ->  ReEQ2/Dependencies/analog-fast.jsfx-inc
  Source/ReEQ2/wide-math.jsfx-inc    ->  ReEQ2/Dependencies/wide-math.jsfx-inc

The only change is that every integer is written in hex (6 becomes 0x6). The compiled code is the
same; Source/README.md says why it matters.

Usage: build.py          write the built files
       build.py --check  write nothing; fail if a built file is out of date, or if the tables
                         include holds a decimal number
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = os.path.join(ROOT, "Source", "ReEQ2")
BUILT = os.path.join(ROOT, "ReEQ2", "Dependencies")
NAMES = ("analog-fast.jsfx-inc", "wide-math.jsfx-inc")
TABLES = "analog-tables.jsfx-inc"

# Strings, character constants, comments and numbers already in hex are left alone; the last
# alternative is a decimal number that is not part of a name.
TOKEN = re.compile(r'"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'|//[^\n]*|/\*.*?\*/'
                   r'|[0$][xX][0-9A-Fa-f]+|\$~\d+'
                   r'|(?<![A-Za-z0-9_.$#])(?:\d+\.?\d*|\.\d+)', re.S)


def is_decimal(token):
    return token[0].isdigit() and token[1:2] not in ("x", "X") or token[0] == "."


def hex_integers(text):
    """Rewrite each decimal integer below 2^32 as hex. Fractions and larger values stay as they are."""
    out, pos = [], 0
    for m in TOKEN.finditer(text):
        token = m.group(0)
        if is_decimal(token) and token.isdigit() and int(token) < 1 << 32:
            out.append(text[pos:m.start()])
            out.append("0x%X" % int(token))
            pos = m.end()
    out.append(text[pos:])
    return "".join(out)


def decimals(text):
    return [m.group(0) for m in TOKEN.finditer(text) if is_decimal(m.group(0))]


def read(path):
    with open(path, encoding="utf-8", newline="") as f:
        return f.read()


def main():
    check = "--check" in sys.argv[1:]
    stale = []
    for name in NAMES:
        built = hex_integers(read(os.path.join(SOURCES, name)))
        target = os.path.join(BUILT, name)
        if check:
            if not os.path.exists(target) or read(target) != built:
                stale.append("%s is out of date: run Source/build.py" % os.path.relpath(target, ROOT))
        else:
            with open(target, "w", encoding="utf-8", newline="") as f:
                f.write(built)
            left = decimals(built)
            print("%s: %d numbers left in decimal (fractions)" % (name, len(left)))
    found = decimals(read(os.path.join(BUILT, TABLES)))
    if found:
        stale.append("%s holds %d decimal numbers (first: %s)" % (TABLES, len(found), found[0]))
    for line in stale:
        print(line)
    sys.exit(1 if stale else 0)


main()
