# ReJJ
Reaper JSFX Plugins

## ReEQ²
`ReEQ2/ReEQ2.jsfx` — a 16-band parametric equalizer with decramped filters up to 30 kHz, per-band dynamic
EQ with sidechain inputs, and a built-in analyser.

ReEQ² 2.3 adds slopes for bells (12 to 48 dB/oct; the steeper ones are flat-topped) and shelves (6 to
36 dB/oct), picked from the slope chips or a node's menu. Dynamic bands stay at 12 dB/oct. Low Cut and High
Cut gain resonance: drag a cut's node up or down, or set its Q. The older resonant cuts are kept as legacy
types, so existing projects sound the same. ReEQ² 2.3 also compiles less than half the code 2.2 did and
keeps its filter tables apart from the rest, for the slow loading reported with 2.2 on Windows.

ReEQ² 2.2 fits the digital filters more closely to their analog curves near Nyquist, including when a
band's frequency is set above it. Existing ReEQ² projects retain their band settings and automation.
High-frequency bands can sound different with the updated filters.

ReEQ² 2.2 also adds a UI size, 100% to 200%, for displays where its text is small (such as 1080p screens at
100% scaling). Each ReEQ² sets it under Settings > Display, and the Theme Editor sets the default (125% until
you change it). The size is limited to what the window can show, so a larger window allows a larger size.
It's saved with the project, but changing it doesn't mark the project as modified, so save after changing
it. The graph's axis labels and the filter pickers' names are also larger.

In ReEQ² 2.2 a double-click on a dial or value resets it to its default, and Alt+double-click (Option on
macOS) opens the box for typing or stepping a value.

Every colour in ReEQ² can be themed. The "ReEQ2 Theme Editor" action (installed with ReEQ2 from ReaPack:
search the Actions window for "ReEQ2 Theme Editor"; in this repository at `Scripts/ReEQ2 Theme Editor.lua`)
edits themes on a preview of ReEQ², with open ReEQ² windows following along, and sets the size new ReEQ²
windows open at and the default UI size (kept in `Data/ReEQ2/settings.txt`). Themes are plain text files in
REAPER's `Data/ReEQ2` folder: `theme.txt` is the one in use, and `Themes/` holds the 16 that come with ReEQ²
(`ReEQ2/Themes` here) and any you save.

Two of ReEQ²'s includes are built by script from readable sources in `Source/`; see `Source/README.md`
before editing them.

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
