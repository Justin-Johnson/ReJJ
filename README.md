# ReJJ
Reaper JSFX Plugins

## ReEQ²
`ReEQ2/ReEQ2.jsfx` — a 16-band parametric equalizer with decramped filters up to 30 kHz, per-band dynamic
EQ with sidechain inputs, and a built-in analyser.

Every colour in ReEQ² can be themed. The "ReEQ2 Theme Editor" action (installed with ReEQ2 from ReaPack:
search the Actions window for "ReEQ2 Theme Editor"; in this repository at `Scripts/ReEQ2 Theme Editor.lua`)
edits themes on a preview of ReEQ², with open ReEQ² windows following along, and sets the size new ReEQ²
windows open at. Themes are plain text files in REAPER's `Data/ReEQ2` folder: `theme.txt` is the one in use,
and `Themes/` holds the 16 that come with ReEQ² (`ReEQ2/Themes` here) and any you save.

## ReEQ 1.2
`ReEQ/ReEQ.jsfx` — the original ReEQ, kept unchanged so existing projects sound as they did. To move a
project to ReEQ², run the "ReEQ upgrade to ReEQ2" action (installed with ReEQ2 from ReaPack: search the
Actions window for "ReEQ upgrade"; in this repository at `Scripts/ReEQ upgrade to ReEQ2.lua`). It keeps every
setting.

## ReSpectrum
`ReSpectrum/ReSpectrum.jsfx` — a spectrum analyser.

## Installing
Add this repository to ReaPack (Extensions > ReaPack > Import repositories) with
`https://raw.githubusercontent.com/Justin-Johnson/ReJJ/master/index.xml`, then install the packages you
want.

MIT License, © 2021–2026 Justin Johnson.
