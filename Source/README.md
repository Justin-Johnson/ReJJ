# Source

Readable sources for the ReEQ2 includes that are built by script. REAPER never loads anything in
this folder, and ReaPack doesn't install it.

| Edit this | Built into |
|---|---|
| `Source/ReEQ2/analog-fast.jsfx-inc` | `ReEQ2/Dependencies/analog-fast.jsfx-inc` |
| `Source/ReEQ2/wide-math.jsfx-inc` | `ReEQ2/Dependencies/wide-math.jsfx-inc` |

After editing a source file:

```bash
python3 Source/build.py
```

Before a release:

```bash
python3 Source/build.py --check
```

The check fails if a built file doesn't match its source, or if a decimal number has got into
`ReEQ2/Dependencies/analog-tables.jsfx-inc`.

## What the build changes

Every integer is written in hex: `co[6]` becomes `co[0x6]`. Fractions such as `0.5` stay as they
are. Nothing else differs, and REAPER compiles the same code from either file.

## Why

REAPER's compiler reads each decimal number in a section with the C function `atof`, giving it a
pointer into the whole section's text. On some C runtimes, `atof` first measures the length of the
text it is given, so every decimal number costs a pass from that number to the end of the section.
ReEQ2's `@init` holds over 6 MB of packed tables. In 2.2.0 thousands of numbers sat ahead of them:
about 100 GB of passes in all. That is the likely reason 2.2.0 took around half a minute to load on
Windows.

Hex numbers are read another way and cost nothing. So:

- `analog-tables.jsfx-inc` holds every packed table and no decimal number. ReEQ2 imports it first,
  ahead of all other code.
- The two big generated includes have their integers in hex.
- `ReEQ2.jsfx` and the smaller includes keep ordinary decimals. They come after the tables, so their
  numbers only pass over the code that follows them.

## Rules to keep

- Never put a large block of text (tables, long strings) after decimal numbers in the same section.
  New tables go in `analog-tables.jsfx-inc`, with offsets and counts in hex.
- Don't edit the two built files by hand; the next build overwrites them.
