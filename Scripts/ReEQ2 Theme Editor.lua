-- @description ReEQ2: theme editor
-- @author Justin Johnson
-- @version 1.2.0
-- @about
--   Edits ReEQ2's colours on a preview of ReEQ2, saves themes used by every ReEQ2, and sets the size
--   new ReEQ2 windows open at and ReEQ2's default UI size. Open ReEQ2 windows follow the edits as you
--   make them.

local r = reaper

----------------------------------------------------------------------------------------------------
-- Files and shared memory
----------------------------------------------------------------------------------------------------

local RES = r.GetResourcePath()
local DATA_DIR = RES .. "/Data/ReEQ2"
local THEMES_DIR = DATA_DIR .. "/Themes"
local THEME_FILE = DATA_DIR .. "/theme.txt"
local SETTINGS_FILE = DATA_DIR .. "/settings.txt"
local JSFX_FILE = RES .. "/Effects/ReJJ/ReEQ2/ReEQ2.jsfx"

-- gmem layout shared with ReEQ2 (options:gmem=ReEQ2): magic, change counter, token count, editor
-- heartbeat, the default UI size (word GM_UI_SIZE), then r, g, b, a per token from GM_TOKENS
local GM_NAME, GM_MAGIC, GM_UI_SIZE, GM_TOKENS = "ReEQ2", 20261031, 4, 8

-- The version of ReEQ2 the preview was translated from
local PREVIEW_FROM = "2.3.0"

local EXT = "ReEQ2 Theme Editor"

----------------------------------------------------------------------------------------------------
-- Tokens: the same ids, order and defaults as ReEQ2's T_ constants and pal_defaults()
----------------------------------------------------------------------------------------------------

-- { key (theme file name), label, group, default 0xRRGGBB, default alpha }
local TOKENS = {
  { key = "text", label = "Text", group = "Text", hex = 0xDFE6E9, a = 1, on = "tile" },
  { key = "text_secondary", label = "Secondary", group = "Text", hex = 0x9AA5AA, a = 1, on = "tile" },
  { key = "text_dim", label = "Dim", group = "Text", hex = 0x848F95, a = 1, on = "tile" },
  { key = "text_faint", label = "Faint", group = "Text", hex = 0x707A7F, a = 1, on = "tile" },
  { key = "text_disabled", label = "Disabled", group = "Text", hex = 0x343C41, a = 1, on = "tile" },
  { key = "badge_text", label = "Badge numbers", group = "Text", hex = 0x101214, a = 1, on = "band1" },
  { key = "bar", label = "Header and toolbar", group = "Surfaces", hex = 0x0D1012, a = 1 },
  { key = "control", label = "Controls", group = "Surfaces", hex = 0x0D1012, a = 1 },
  { key = "control_hover", label = "Hover", group = "Surfaces", hex = 0x1A1F22, a = 1 },
  { key = "tile", label = "Tiles", group = "Surfaces", hex = 0x101315, a = 1 },
  { key = "panel", label = "Band panel", group = "Surfaces", hex = 0x121518, a = 0.78 },
  { key = "popover", label = "Popovers", group = "Surfaces", hex = 0x121518, a = 1 },
  { key = "scrim", label = "Backdrop", group = "Surfaces", hex = 0x000000, a = 0.45 },
  { key = "hover_wash", label = "Hover tint", group = "Surfaces", hex = 0xFFFFFF, a = 1 },
  { key = "border", label = "Borders", group = "Surfaces", hex = 0x2A3135, a = 1 },
  { key = "border_subtle", label = "Dividers", group = "Surfaces", hex = 0x20262A, a = 1 },
  { key = "border_hover", label = "Hover borders", group = "Surfaces", hex = 0x343C40, a = 1 },
  { key = "dial_face", label = "Dial face", group = "Controls", hex = 0x15181A, a = 1 },
  { key = "dial_face_lit", label = "Dial centre", group = "Controls", hex = 0x22272A, a = 1 },
  { key = "dial_track", label = "Tracks", group = "Controls", hex = 0x22292D, a = 1 },
  { key = "dial_rim", label = "Dial rim", group = "Controls", hex = 0x0A0C0D, a = 1 },
  { key = "dial_edge", label = "Dial edge", group = "Controls", hex = 0x30373B, a = 1 },
  { key = "dial_pointer", label = "Pointer", group = "Controls", hex = 0xEEF2F4, a = 1 },
  { key = "dial_shadow", label = "Pointer shadow", group = "Controls", hex = 0x000000, a = 0.6 },
  { key = "meter_ok", label = "Meter", group = "Controls", hex = 0x5FBF7A, a = 1 },
  { key = "meter_warn", label = "Meter, high", group = "Controls", hex = 0xE3A84B, a = 1 },
  { key = "accent", label = "Accent", group = "Accent", hex = 0x5CC8EA, a = 1, on = "accent_fill" },
  { key = "accent_fill", label = "Accent fill", group = "Accent", hex = 0x0F2A33, a = 1 },
  { key = "accent_border", label = "Accent border", group = "Accent", hex = 0x1D5A6D, a = 1 },
  { key = "selected", label = "Chosen", group = "Accent", hex = 0xF3DCB2, a = 1, on = "tile" },
  { key = "danger", label = "Delete", group = "Accent", hex = 0xF0838F, a = 1 },
  { key = "danger_fill", label = "Delete fill", group = "Accent", hex = 0x2A1215, a = 1 },
  { key = "danger_border", label = "Delete border", group = "Accent", hex = 0x6A2A31, a = 1 },
  { key = "clip", label = "Clip", group = "Accent", hex = 0xE24B4A, a = 1 },
  { key = "graph_bg", label = "Background", group = "Graph", hex = 0x101316, a = 1 },
  { key = "graph_bg_low", label = "Background, bottom", group = "Graph", hex = 0x08090A, a = 1 },
  { key = "graph_shade", label = "Lower shade", group = "Graph", hex = 0x000000, a = 0.55 },
  { key = "grid", label = "Grid", group = "Graph", hex = 0xFFFFFF, a = 0.07 },
  { key = "grid_decade", label = "Grid decade", group = "Graph", hex = 0xFFFFFF, a = 0.13 },
  { key = "zero_line", label = "0 dB line", group = "Graph", hex = 0xFFFFFF, a = 0.16 },
  { key = "db_label", label = "dB labels", group = "Graph", hex = 0xBFBF00, a = 1, on = "graph_bg" },
  { key = "axis_label", label = "Frequency labels", group = "Graph", hex = 0x707A7F, a = 1, on = "graph_bg" },
  { key = "curve", label = "Curve", group = "Graph", hex = 0xFFFFFF, a = 1 },
  { key = "curve_mid", label = "Curve, mid", group = "Graph", hex = 0x5CBE62, a = 1 },
  { key = "curve_side", label = "Curve, side", group = "Graph", hex = 0x5BECFC, a = 1 },
  { key = "curve_left", label = "Curve, left", group = "Graph", hex = 0xF0C91B, a = 1 },
  { key = "curve_right", label = "Curve, right", group = "Graph", hex = 0xD54142, a = 1 },
  { key = "band_area", label = "Band area", group = "Graph", hex = 0x000000, a = 0.5 },
  { key = "highlight", label = "Highlight", group = "Graph", hex = 0xFFFFFF, a = 1 },
  { key = "node_edge", label = "Node edge", group = "Graph", hex = 0x000000, a = 0.6 },
  { key = "listen", label = "Listen lines", group = "Graph", hex = 0xF0654C, a = 1 },
  { key = "listen_shadow", label = "Listen shadow", group = "Graph", hex = 0x000000, a = 0.2 },
  { key = "band1", label = "Band 1", group = "Bands", hex = 0xE3A84B, a = 1 },
  { key = "band2", label = "Band 2", group = "Bands", hex = 0x9B86E8, a = 1 },
  { key = "band3", label = "Band 3", group = "Bands", hex = 0x6CC28E, a = 1 },
  { key = "band4", label = "Band 4", group = "Bands", hex = 0xE07AA0, a = 1 },
  { key = "band5", label = "Band 5", group = "Bands", hex = 0x5E9CE6, a = 1 },
  { key = "band6", label = "Band 6", group = "Bands", hex = 0xB5CF5A, a = 1 },
  { key = "band7", label = "Band 7", group = "Bands", hex = 0xE8875F, a = 1 },
  { key = "band8", label = "Band 8", group = "Bands", hex = 0x45BFAE, a = 1 },
  { key = "an_fill", label = "Fill", group = "Analyser", hex = 0x5D8AA0, a = 0.35 },
  { key = "an_fill_2", label = "Fill, side", group = "Analyser", hex = 0xB0966E, a = 0.28 },
  { key = "an_line", label = "Line", group = "Analyser", hex = 0x72D7FD, a = 1 },
  { key = "an_line_2", label = "Line, side", group = "Analyser", hex = 0xFDB915, a = 1 },
  { key = "an_heat_low", label = "Heat, quiet", group = "Analyser", hex = 0x5C3456, a = 1 },
  { key = "an_heat_high", label = "Heat, loud", group = "Analyser", hex = 0xF05662, a = 0.85 },
  { key = "an_heat_2", label = "Heat, side", group = "Analyser", hex = 0xB0966E, a = 0.12 },
  { key = "an_pre_eq", label = "Pre-EQ", group = "Analyser", hex = 0x8A9499, a = 0.5 },
  { key = "an_pre_eq_2", label = "Pre-EQ, side", group = "Analyser", hex = 0x8A9499, a = 0.4 },
  { key = "an_ghost", label = "Ghost", group = "Analyser", hex = 0xDBE3E5, a = 1 },
  { key = "an_listen", label = "Listen", group = "Analyser", hex = 0xF0654C, a = 1 },
  { key = "wordmark_re", label = "Re", group = "Wordmark", hex = 0xE8EEF0, a = 1 },
  { key = "wordmark_eq", label = "EQ", group = "Wordmark", hex = 0xE3A84B, a = 1 },
}

local GROUPS = { "Text", "Surfaces", "Controls", "Accent", "Graph", "Bands", "Analyser", "Wordmark" }

local by_key = {}
for i, t in ipairs(TOKENS) do t.id = i - 1; by_key[t.key] = t end

-- The theme being edited: per token { hex, a }, plus its name
local theme = { name = "Default", c = {} }

local function defaults()
  local c = {}
  for _, t in ipairs(TOKENS) do c[t.key] = { hex = t.hex, a = t.a } end
  return c
end

----------------------------------------------------------------------------------------------------
-- Colour maths
----------------------------------------------------------------------------------------------------

local function unpack_hex(hex)
  return (hex >> 16) & 255, (hex >> 8) & 255, hex & 255
end

local function pack_hex(cr, cg, cb)
  local function c(v) return math.max(0, math.min(255, math.floor(v + 0.5))) end
  return (c(cr) << 16) | (c(cg) << 8) | c(cb)
end

-- h in degrees, s and v 0..1; r, g, b 0..255
local function hsv_to_rgb(h, s, v)
  local function f(n)
    local k = (n + h / 60) % 6
    return 255 * (v - v * s * math.max(0, math.min(k, 4 - k, 1)))
  end
  return f(5), f(3), f(1)
end

local function rgb_to_hsv(cr, cg, cb)
  cr, cg, cb = cr / 255, cg / 255, cb / 255
  local mx, mn = math.max(cr, cg, cb), math.min(cr, cg, cb)
  local d, h = mx - mn, 0
  if d > 0 then
    if mx == cr then h = ((cg - cb) / d) % 6
    elseif mx == cg then h = (cb - cr) / d + 2
    else h = (cr - cg) / d + 4 end
    h = h * 60
  end
  return h, mx > 0 and d / mx or 0, mx
end

-- WCAG relative luminance and contrast ratio
local function luminance(hex)
  local function ch(v)
    v = v / 255
    return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
  end
  local cr, cg, cb = unpack_hex(hex)
  return 0.2126 * ch(cr) + 0.7152 * ch(cg) + 0.0722 * ch(cb)
end

local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end

local function hex_string(hex)
  return string.format("#%06X", hex)
end

----------------------------------------------------------------------------------------------------
-- Theme files: "key = #RRGGBB [alpha]", "name = ...", "#" comments. Unknown keys are ignored and
-- missing ones keep their defaults, as in ReEQ2.
----------------------------------------------------------------------------------------------------

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parse_theme(text)
  local t = { name = "Untitled", c = defaults() }
  for line in text:gmatch("[^\r\n]+") do
    line = trim(line)
    if line ~= "" and line:sub(1, 1) ~= "#" then
      local k, v = line:match("^([^=]-)%s*=%s*(.-)$")
      if k then
        k = trim(k)
        if k == "name" then
          t.name = v
        elseif t.c[k] then
          local hx, rest = v:match("^#(%x%x%x%x%x%x)%s*(.-)$")
          if hx then
            local a = tonumber(rest) or 1
            t.c[k] = { hex = tonumber(hx, 16), a = math.max(0, math.min(1, a)) }
          end
        end
      end
    end
  end
  return t
end

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("a")
  f:close()
  return s
end

local function load_theme(path)
  local s = read_file(path)
  return s and parse_theme(s)
end

local function theme_text(t)
  local out = { "# ReEQ2 theme", "name = " .. t.name }
  local group
  for _, tok in ipairs(TOKENS) do
    if tok.group ~= group then
      group = tok.group
      out[#out + 1] = ""
      out[#out + 1] = "# " .. group
    end
    local c = t.c[tok.key]
    local line = string.format("%s = %s", tok.key, hex_string(c.hex))
    if c.a < 1 then line = line .. string.format(" %.3g", c.a) end
    out[#out + 1] = line
  end
  return table.concat(out, "\n") .. "\n"
end

-- Write through a temporary file, so a failed write never leaves half a file
local function write_file(path, s)
  local tmp = path .. ".tmp"
  local f = io.open(tmp, "wb")
  if not f then return false end
  f:write(s)
  f:close()
  os.remove(path)
  return os.rename(tmp, path)
end

local function save_theme(t, path)
  r.RecursiveCreateDirectory(DATA_DIR, 0)
  r.RecursiveCreateDirectory(THEMES_DIR, 0)
  return write_file(path, theme_text(t))
end

----------------------------------------------------------------------------------------------------
-- Settings: Data/ReEQ2/settings.txt, "ui_size = 125" and "#" comments, read by every ReEQ2. The UI
-- size is the default for ReEQ2 windows; one set in a ReEQ2's own Settings keeps its size. As in ReEQ2
-- (UI_SIZE_INITIAL), no file or a size other than these is 125.
----------------------------------------------------------------------------------------------------

local UI_SIZES = { 100, 125, 150, 175, 200 }
local UI_SIZE_INITIAL = 125

local function valid_ui_size(v)
  for _, s in ipairs(UI_SIZES) do
    if v == s then return true end
  end
  return false
end

local function parse_settings(text)
  local ui = UI_SIZE_INITIAL
  for line in text:gmatch("[^\r\n]+") do
    line = trim(line)
    if line ~= "" and line:sub(1, 1) ~= "#" then
      local k, v = line:match("^([^=]-)%s*=%s*(.-)$")
      if k and trim(k) == "ui_size" then
        local n = tonumber(v:match("^%d+$") or "")
        ui = (n and valid_ui_size(n)) and n or UI_SIZE_INITIAL
      end
    end
  end
  return ui
end

local function load_settings()
  local s = read_file(SETTINGS_FILE)
  return s and parse_settings(s) or UI_SIZE_INITIAL
end

local function settings_text(ui)
  return "# ReEQ2 settings, written by the ReEQ2 Theme Editor\n" .. string.format("ui_size = %d\n", ui)
end

local function save_settings(ui)
  r.RecursiveCreateDirectory(DATA_DIR, 0)
  return write_file(SETTINGS_FILE, settings_text(ui))
end

-- Theme files in Themes/, sorted by name
local function list_themes()
  local list, i = {}, 0
  r.EnumerateFiles(THEMES_DIR, -1)
  while true do
    local f = r.EnumerateFiles(THEMES_DIR, i)
    if not f then break end
    if f:lower():match("%.txt$") then
      local t = load_theme(THEMES_DIR .. "/" .. f)
      if t then t.file = f; list[#list + 1] = t end
    end
    i = i + 1
  end
  table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
  return list
end

local function safe_file_name(name)
  local s = trim(name:gsub("[^%w%s%-_]", ""))
  return s ~= "" and s or "Untitled"
end

----------------------------------------------------------------------------------------------------
-- Live updates to open ReEQ2 windows
----------------------------------------------------------------------------------------------------

local gm_counter = 0
-- The default UI size, as settings.txt holds it (saved as soon as it's picked)
local ui_size = UI_SIZE_INITIAL
-- Moves on every colour change; the preview draws itself again when it does
local preview_version = 0

-- Open ReEQ2 windows get the theme at most every LIVE_GAP seconds; a change in between waits for the
-- next frame (flush_live), so the last one always arrives
local LIVE_GAP = 0.04
local live_t, live_pending = 0, nil

local function send_live(t)
  live_t, live_pending = r.time_precise(), nil
  r.gmem_attach(GM_NAME)
  for _, tok in ipairs(TOKENS) do
    local c = t.c[tok.key]
    local cr, cg, cb = unpack_hex(c.hex)
    local b = GM_TOKENS + tok.id * 4
    r.gmem_write(b, cr); r.gmem_write(b + 1, cg); r.gmem_write(b + 2, cb); r.gmem_write(b + 3, c.a)
  end
  r.gmem_write(GM_UI_SIZE, ui_size)
  r.gmem_write(0, GM_MAGIC)
  r.gmem_write(2, #TOKENS)
  r.gmem_write(3, r.time_precise())
  gm_counter = math.floor(r.gmem_read(1)) + 1
  r.gmem_write(1, gm_counter)
end

local function push_live(t)
  preview_version = preview_version + 1
  if r.time_precise() - live_t >= LIVE_GAP then send_live(t) else live_pending = t end
end

local function flush_live()
  if live_pending and r.time_precise() - live_t >= LIVE_GAP then send_live(live_pending) end
end

----------------------------------------------------------------------------------------------------
-- Window size: the "@gfx W H" line of the installed ReEQ2.jsfx
----------------------------------------------------------------------------------------------------

local DEFAULT_W, DEFAULT_H = 922, 564
local MIN_W, MIN_H, MAX_W, MAX_H = 640, 400, 3840, 2160
-- REAPER's title and preset bars above a floating FX window's own area (points; measured on macOS,
-- not yet on Windows)
local FX_BARS = 53

local function jsfx_size()
  local s = read_file(JSFX_FILE)
  if not s then return nil end
  local w, h = s:match("\n@gfx (%d+) (%d+)\r?\n")
  return tonumber(w), tonumber(h), s:match("\nversion:%s*([%d%.]+)")
end

-- A file inside a git checkout is somebody's source, not an install
local function in_git_checkout(path)
  local dir = path:match("^(.*)/[^/]*$")
  while dir and dir ~= "" do
    if r.file_exists(dir .. "/.git/HEAD") or r.file_exists(dir .. "/.git") then return true end
    dir = dir:match("^(.*)/[^/]*$")
  end
  return false
end

-- Returns true, or false and a reason
local function set_jsfx_size(w, h)
  if w < MIN_W or w > MAX_W or h < MIN_H or h > MAX_H then
    return false, string.format("Use %d to %d wide and %d to %d high.", MIN_W, MAX_W, MIN_H, MAX_H)
  end
  local s = read_file(JSFX_FILE)
  if not s then return false, "ReEQ2 isn't installed at " .. JSFX_FILE .. "." end
  if in_git_checkout(JSFX_FILE) then
    return false, "That ReEQ2.jsfx is inside a git checkout, so it isn't changed from here."
  end
  local n
  s, n = s:gsub("\n@gfx %d+ %d+(\r?\n)", string.format("\n@gfx %d %d%%1", w, h))
  if n ~= 1 then return false, "Couldn't find ReEQ2's window size line." end
  if not write_file(JSFX_FILE, s) then return false, "Couldn't write " .. JSFX_FILE .. "." end
  r.SetExtState(EXT, "size", string.format("%d %d", w, h), true)
  return true
end

-- The window area of an open floating ReEQ2 (the last one found), from the "FLOAT x y w h" line that
-- follows its <JS ...> block in the track chunk (FLOATPOS when the window is closed)
local function open_reeq2_size()
  local w, h
  for ti = -1, r.CountTracks(0) - 1 do
    local tr = ti < 0 and r.GetMasterTrack(0) or r.GetTrack(0, ti)
    local _, chunk = r.GetTrackStateChunk(tr, "", false)
    local pos = 1
    while true do
      local s, e, js = chunk:find("<JS ([^\n]*)\n", pos)
      if not s then break end
      local close = chunk:find("\n>", e, true)
      if not close then break end
      local line = chunk:match("^%s*([^\n]*)", close + 2)
      local fw, fh = line:match("^FLOAT %-?%d+ %-?%d+ (%d+) (%d+)")
      if fw and js:find("ReEQ2[/\\]ReEQ2%.jsfx") then w, h = tonumber(fw), tonumber(fh) - FX_BARS end
      pos = close + 2
    end
  end
  return w, h
end

----------------------------------------------------------------------------------------------------
-- Editing state
----------------------------------------------------------------------------------------------------

local function copy_colours(c)
  local o = {}
  for k, v in pairs(c) do o[k] = { hex = v.hex, a = v.a } end
  return o
end

local function same_colours(a, b)
  for k, v in pairs(a) do
    if not b[k] or b[k].hex ~= v.hex or math.abs(b[k].a - v.a) > 1e-4 then return false end
  end
  return true
end

local saved = { name = "Default", c = defaults() }   -- what theme.txt holds
local undo = {}
local sel                                             -- selected token key
local pk = { h = 0, s = 0, v = 0, a = 1 }             -- the picker, in HSV
local recent = {}
local view = "main"                                   -- or "gallery", "size"
local gallery = {}
local note, note_t = nil, 0                           -- a message shown for a few seconds

local function say(msg) note, note_t = msg, r.time_precise() end

local function dirty() return theme.name ~= saved.name or not same_colours(theme.c, saved.c) end

local function push_undo()
  undo[#undo + 1] = { name = theme.name, c = copy_colours(theme.c) }
  if #undo > 200 then table.remove(undo, 1) end
end

local function pick_from_token()
  local c = theme.c[sel]
  local h, s, v = rgb_to_hsv(unpack_hex(c.hex))
  -- Keep the hue when a grey has none
  if s > 0 and v > 0 then pk.h = h end
  pk.s, pk.v, pk.a = s, v, c.a
end

local function select_token(key)
  if sel and sel ~= key then
    local hex = theme.c[sel].hex
    for i = #recent, 1, -1 do if recent[i] == hex then table.remove(recent, i) end end
    table.insert(recent, 1, hex)
    if #recent > 10 then recent[#recent] = nil end
  end
  sel = key
  pick_from_token()
end

-- Whole-theme adjustments act on a base taken when one is first moved after another edit
local whole = { hue = 0, sat = 100, bri = 100, base = nil }

local function whole_reset() whole.hue, whole.sat, whole.bri, whole.base = 0, 100, 100, nil end

local function whole_apply()
  for k, c in pairs(whole.base) do
    local h, s, v = rgb_to_hsv(unpack_hex(c.hex))
    local nr, ng, nb = hsv_to_rgb((h + whole.hue) % 360, math.min(1, s * whole.sat / 100), math.min(1, v * whole.bri / 100))
    theme.c[k] = { hex = pack_hex(nr, ng, nb), a = c.a }
  end
  pick_from_token()
  push_live(theme)
end

-- Band colours from the first band's hue: even spacing round the wheel, a warm or a cool family
local function band_harmony(kind)
  push_undo(); whole_reset()
  local h0 = rgb_to_hsv(unpack_hex(theme.c.band1.hex))
  for i = 0, 7 do
    local h = kind == "even" and h0 + i * 45 or kind == "warm" and h0 - 40 + i * 13 or 170 + i * 14
    local s, v = 0.62, 0.9 - (i % 2) * 0.1
    theme.c["band" .. (i + 1)].hex = pack_hex(hsv_to_rgb(h % 360, s, v))
  end
  pick_from_token()
  push_live(theme)
end

-- The picker changed the selected token
-- The picker moved: only a real change goes anywhere (holding the mouse still changes nothing)
local function picker_changed()
  local c = theme.c[sel]
  local hex = pack_hex(hsv_to_rgb(pk.h, pk.s, pk.v))
  if hex == c.hex and math.abs(pk.a - c.a) < 1e-4 then return end
  whole_reset()
  c.hex, c.a = hex, pk.a
  push_live(theme)
end

local function load_into_editor(t)
  push_undo(); whole_reset()
  theme.name, theme.c = t.name, copy_colours(t.c)
  pick_from_token()
  push_live(theme)
end

----------------------------------------------------------------------------------------------------
-- Drawing and widgets (the editor's own chrome; sizes in points, scaled by S)
----------------------------------------------------------------------------------------------------

local S = 1
local mouse = { x = 0, y = 0, down = false, press = false, release = false, rpress = false, wheel = 0, capture = nil }

local function rgb(hex, a)
  local cr, cg, cb = unpack_hex(hex)
  gfx.set(cr / 255, cg / 255, cb / 255, a or 1)
end

local function pt(v) return math.floor(v * S + 0.5) end

local function inside(x, y, w, h)
  return mouse.x >= x and mouse.x < x + w and mouse.y >= y and mouse.y < y + h
end

local function font(size, bold)
  gfx.setfont(1, "Arial", pt(size), bold and string.byte("b") or 0)
end

local function text(s, x, y, w, h, align, hex, size, bold)
  font(size or 13, bold)
  rgb(hex or 0xDFE6E9)
  gfx.x, gfx.y = x, y
  gfx.drawstr(s, (align or 0) | 4, x + w, y + h)
end

-- Filled rounded rectangle, corners drawn as scanlines so translucent fills stay even (ReEQ2's
-- ui_fill_rrect)
local function fill_rrect(x, y, w, h, rad)
  x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
  rad = math.floor(math.min(rad, math.min(w, h) * 0.5))
  local a0 = gfx.a
  gfx.rect(x, y + rad, w, h - 2 * rad, 1)
  for i = 0, rad - 1 do
    local dy = rad - i - 0.5
    local dx = rad - math.sqrt(math.max(rad * rad - dy * dy, 0))
    local xi = math.ceil(dx)
    local fr = xi - dx
    gfx.rect(x + xi, y + i, w - 2 * xi, 1, 1)
    gfx.rect(x + xi, y + h - 1 - i, w - 2 * xi, 1, 1)
    if fr > 0.02 then
      gfx.a = a0 * fr
      gfx.rect(x + xi - 1, y + i, 1, 1, 1)
      gfx.rect(x + w - xi, y + i, 1, 1, 1)
      gfx.rect(x + xi - 1, y + h - 1 - i, 1, 1, 1)
      gfx.rect(x + w - xi, y + h - 1 - i, 1, 1, 1)
      gfx.a = a0
    end
  end
end

local function box(x, y, w, h, fill, border, radius)
  radius = radius or pt(5)
  if fill then rgb(fill); fill_rrect(x, y, w, h, radius) end
  if border then rgb(border); gfx.roundrect(x, y, w - 1, h - 1, radius, 1) end
end

-- A checkerboard behind translucent colours
local function checker(x, y, w, h)
  local c = pt(4)
  for j = 0, math.ceil(h / c) - 1 do
    for i = 0, math.ceil(w / c) - 1 do
      gfx.set(((i + j) % 2 == 0) and 0.27 or 0.13, ((i + j) % 2 == 0) and 0.27 or 0.13, ((i + j) % 2 == 0) and 0.27 or 0.13, 1)
      gfx.rect(x + i * c, y + j * c, math.min(c, x + w - (x + i * c)), math.min(c, y + h - (y + j * c)), 1)
    end
  end
end

local function swatch(x, y, w, h, c)
  checker(x, y, w, h)
  rgb(c.hex, c.a)
  gfx.rect(x, y, w, h, 1)
  gfx.set(0.17, 0.2, 0.22, 1)
  gfx.rect(x, y, w, h, 0)
end

-- A button; returns true when clicked
local function button(label, x, y, w, h, on)
  local hov = inside(x, y, w, h)
  box(x, y, w, h, on and 0x0F2A33 or hov and 0x1F2427 or 0x1A1F22, on and 0x1D5A6D or 0x2C3438)
  text(label, x, y, w, h, 1, on and 0x5CC8EA or hov and 0xDFE6E9 or 0xC8D0D4, 12)
  return hov and mouse.press and not mouse.capture
end

local function button_w(label)
  font(12)
  return gfx.measurestr(label) + pt(18)
end

-- A horizontal slider; v in lo..hi, returns the new value
local function hslider(id, x, y, w, v, lo, hi)
  local h = pt(14)
  if inside(x, y - pt(3), w, h + pt(6)) and mouse.press and not mouse.capture then mouse.capture = id end
  if mouse.capture == id then v = lo + (hi - lo) * math.max(0, math.min(1, (mouse.x - x) / w)) end
  local f = (v - lo) / (hi - lo)
  box(x, y + h / 2 - pt(2), w, pt(4), 0x2C3438)
  box(x, y + h / 2 - pt(2), math.floor(w * f), pt(4), 0x5CC8EA)
  gfx.set(0.87, 0.9, 0.91, 1)
  gfx.circle(x + w * f, y + h / 2, pt(6), 1, 1)
  return v
end

local function caption(s, x, y)
  font(11)
  rgb(0x848F95)
  gfx.x, gfx.y = x, y
  gfx.drawstr(s)
end

----------------------------------------------------------------------------------------------------
-- The colour picker
----------------------------------------------------------------------------------------------------

local HUES = { { 1, 0, 0 }, { 1, 1, 0 }, { 0, 1, 0 }, { 0, 1, 1 }, { 0, 0, 1 }, { 1, 0, 1 }, { 1, 0, 0 } }

local function ask_hex()
  local c = theme.c[sel]
  local ok, s = r.GetUserInputs("ReEQ2 colour", 2, "Colour (#RRGGBB),Alpha (0-100%),extrawidth=40",
    hex_string(c.hex) .. "," .. math.floor(c.a * 100 + 0.5))
  if not ok then return end
  local hx, al = s:match("^%s*#?(%x%x%x%x%x%x)%s*,%s*([%d%.]+)%s*$")
  if not hx then say("Use a colour like #9AA5AA and an alpha from 0 to 100."); return end
  push_undo(); whole_reset()
  c.hex, c.a = tonumber(hx, 16), math.max(0, math.min(1, tonumber(al) / 100))
  pick_from_token()
  push_live(theme)
end

local function system_picker()
  local ok, native = r.GR_SelectColor(r.GetMainHwnd())
  if ok == 0 then return end
  local cr, cg, cb = r.ColorFromNative(native)
  push_undo(); whole_reset()
  theme.c[sel].hex = pack_hex(cr, cg, cb)
  pick_from_token()
  push_live(theme)
end

-- Draws the picker in x, y, w and returns its height
local function picker(x, y, w)
  local tok = by_key[sel]
  local pad = pt(10)
  local ix, iw = x + pad, w - 2 * pad
  local cy = y + pad
  caption("EDITING", ix, cy); cy = cy + pt(14)
  text(tok.label, ix, cy, iw, pt(18), 0, 0xDFE6E9, 15, true); cy = cy + pt(24)

  -- Saturation (across) and brightness (down) for the current hue
  local fh = pt(130)
  local hr, hg, hb = hsv_to_rgb(pk.h, 1, 1)
  gfx.gradrect(ix, cy, iw, fh, hr / 255, hg / 255, hb / 255, 1)
  gfx.gradrect(ix, cy, iw, fh, 1, 1, 1, 1, 0, 0, 0, -1 / iw)
  gfx.gradrect(ix, cy, iw, fh, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 / fh)
  if inside(ix, cy, iw, fh) and mouse.press and not mouse.capture then mouse.capture = "sv"; push_undo() end
  if mouse.capture == "sv" then
    pk.s = math.max(0, math.min(1, (mouse.x - ix) / iw))
    pk.v = 1 - math.max(0, math.min(1, (mouse.y - cy) / fh))
    picker_changed()
  end
  gfx.set(1, 1, 1, 1)
  gfx.circle(ix + pk.s * iw, cy + (1 - pk.v) * fh, pt(6), 0, 1)
  gfx.set(0, 0, 0, 0.5)
  gfx.circle(ix + pk.s * iw, cy + (1 - pk.v) * fh, pt(7), 0, 1)
  cy = cy + fh + pt(8)

  -- Hue: six straight runs between the primaries
  local sh = pt(12)
  for i = 1, 6 do
    local a, b = HUES[i], HUES[i + 1]
    local sx = ix + math.floor(iw * (i - 1) / 6)
    local sw = ix + math.floor(iw * i / 6) - sx
    gfx.gradrect(sx, cy, sw, sh, a[1], a[2], a[3], 1, (b[1] - a[1]) / sw, (b[2] - a[2]) / sw, (b[3] - a[3]) / sw, 0)
  end
  if inside(ix, cy - pt(2), iw, sh + pt(4)) and mouse.press and not mouse.capture then mouse.capture = "hue"; push_undo() end
  if mouse.capture == "hue" then
    pk.h = 359.9 * math.max(0, math.min(1, (mouse.x - ix) / iw))
    picker_changed()
  end
  gfx.set(1, 1, 1, 1)
  gfx.rect(ix + pk.h / 360 * iw - pt(2), cy - pt(1), pt(4), sh + pt(2), 0)
  cy = cy + sh + pt(7)

  -- Alpha, over a checkerboard
  local cr, cg, cb = hsv_to_rgb(pk.h, pk.s, pk.v)
  checker(ix, cy, iw, sh)
  gfx.gradrect(ix, cy, iw, sh, cr / 255, cg / 255, cb / 255, 0, 0, 0, 0, 1 / iw)
  if inside(ix, cy - pt(2), iw, sh + pt(4)) and mouse.press and not mouse.capture then mouse.capture = "alpha"; push_undo() end
  if mouse.capture == "alpha" then
    pk.a = math.max(0, math.min(1, (mouse.x - ix) / iw))
    picker_changed()
  end
  gfx.set(1, 1, 1, 1)
  gfx.rect(ix + pk.a * iw - pt(2), cy - pt(1), pt(4), sh + pt(2), 0)
  cy = cy + sh + pt(10)

  -- The colour, its hex and alpha (click either to type)
  local c = theme.c[sel]
  swatch(ix, cy, pt(34), pt(26), c)
  local hx = ix + pt(42)
  local hov = inside(hx, cy, pt(150), pt(26))
  box(hx, cy, pt(84), pt(26), 0x0D1012, hov and 0x5CC8EA or 0x2C3438)
  text(hex_string(c.hex), hx, cy, pt(84), pt(26), 1, 0xDFE6E9, 13)
  box(hx + pt(90), cy, pt(54), pt(26), 0x0D1012, hov and 0x5CC8EA or 0x2C3438)
  text(string.format("%d%%", math.floor(c.a * 100 + 0.5)), hx + pt(90), cy, pt(54), pt(26), 1, c.a < 1 and 0x5CC8EA or 0xDFE6E9, 13)
  if hov and mouse.press and not mouse.capture then ask_hex() end
  cy = cy + pt(32)

  -- Text colours: their contrast on the surface they sit on
  if tok.on then
    local ratio = contrast(c.hex, theme.c[tok.on].hex)
    text(string.format("Contrast on %s", by_key[tok.on].label:lower()), ix, cy, iw, pt(16), 0, 0x848F95, 12)
    text(string.format("%.1f:1", ratio), ix, cy, iw, pt(16), 2, ratio >= 4.5 and 0x6CC28E or 0xE8875F, 12, true)
  end
  cy = cy + pt(22)

  -- Colours already in the theme, then recently used ones: click to use one here
  local function swatch_row(label, list)
    caption(label, ix, cy); cy = cy + pt(14)
    local sz, gap = pt(18), pt(4)
    local per = math.floor((iw + gap) / (sz + gap))
    for i, hex in ipairs(list) do
      local sx = ix + ((i - 1) % per) * (sz + gap)
      local sy = cy + math.floor((i - 1) / per) * (sz + gap)
      rgb(hex); fill_rrect(sx, sy, sz, sz, pt(3))
      if inside(sx, sy, sz, sz) then
        gfx.set(0.36, 0.78, 0.92, 1); gfx.roundrect(sx - 1, sy - 1, sz + 1, sz + 1, pt(3), 1)
        if mouse.press and not mouse.capture then
          push_undo(); whole_reset()
          theme.c[sel].hex = hex
          pick_from_token()
          push_live(theme)
        end
      end
    end
    cy = cy + (math.floor((#list - 1) / per) + 1) * (sz + gap) + pt(6)
  end
  local seen, uniq = {}, {}
  for _, t in ipairs(TOKENS) do
    local hex = theme.c[t.key].hex
    if not seen[hex] then seen[hex] = true; uniq[#uniq + 1] = hex end
  end
  swatch_row("THIS THEME", uniq)
  if #recent > 0 then swatch_row("RECENT", recent) end

  local bx = ix
  if button("System picker", bx, cy, button_w("System picker"), pt(24)) then system_picker() end
  bx = bx + button_w("System picker") + pt(6)
  if button("Reset", bx, cy, button_w("Reset"), pt(24)) then
    push_undo(); whole_reset()
    theme.c[sel] = { hex = tok.hex, a = tok.a }
    pick_from_token()
    push_live(theme)
  end
  cy = cy + pt(24) + pad
  return cy - y
end

----------------------------------------------------------------------------------------------------
-- Token lists, by group
----------------------------------------------------------------------------------------------------

local list_scroll = 0

-- Draws the groups in cols columns in x, y, w, h (scrolls with the wheel)
local function token_lists(x, y, w, h, cols)
  local gap = pt(8)
  local cw = math.floor((w - gap * (cols - 1)) / cols)
  local rh = pt(20)
  local heights = {}
  for i = 1, cols do heights[i] = 0 end
  -- Place each group in the shortest column
  local placed = {}
  for _, g in ipairs(GROUPS) do
    local n = 0
    for _, t in ipairs(TOKENS) do if t.group == g then n = n + 1 end end
    local col = 1
    for i = 2, cols do if heights[i] < heights[col] then col = i end end
    placed[#placed + 1] = { g = g, col = col, y = heights[col] }
    heights[col] = heights[col] + pt(26) + n * rh + gap
  end
  local total = math.max(table.unpack(heights))
  if inside(x, y, w, h) and mouse.wheel ~= 0 then
    list_scroll = list_scroll - mouse.wheel * pt(30)
  end
  list_scroll = math.max(0, math.min(list_scroll, math.max(0, total - h)))

  for _, p in ipairs(placed) do
    local gx = x + (p.col - 1) * (cw + gap)
    local gy = y + p.y - list_scroll
    local n = 0
    for _, t in ipairs(TOKENS) do if t.group == p.g then n = n + 1 end end
    local gh = pt(26) + n * rh
    if gy + gh > y and gy < y + h then
      box(gx, gy, cw, gh, 0x121618, 0x232A2E, pt(8))
      caption(p.g:upper(), gx + pt(8), gy + pt(8))
      local ry = gy + pt(22)
      for _, t in ipairs(TOKENS) do
        if t.group == p.g then
          local c = theme.c[t.key]
          local hov = inside(gx + pt(4), ry, cw - pt(8), rh) and inside(x, y, w, h)
          if t.key == sel or hov then box(gx + pt(4), ry, cw - pt(8), rh, t.key == sel and 0x0F2A33 or 0x1A1F22) end
          swatch(gx + pt(8), ry + pt(3), pt(14), pt(14), c)
          text(t.label, gx + pt(28), ry, cw - pt(100), rh, 0, 0xDFE6E9, 12)
          text(hex_string(c.hex):sub(2), gx + cw - pt(96), ry, pt(56), rh, 2, 0x848F95, 11)
          text(string.format("%d%%", math.floor(c.a * 100 + 0.5)), gx + cw - pt(40), ry, pt(30), rh, 2,
            c.a < 1 and 0x5CC8EA or 0x4A5257, 11)
          if hov and mouse.press and not mouse.capture then select_token(t.key) end
          ry = ry + rh
        end
      end
    end
  end
end

----------------------------------------------------------------------------------------------------
-- Window size popover
----------------------------------------------------------------------------------------------------

local size = { w = DEFAULT_W, h = DEFAULT_H, file_w = nil, file_h = nil, version = nil, msg = nil }
local SIZE_PRESETS = { { "Laptop", 922, 564 }, { "Medium", 1100, 680 }, { "Large", 1280, 800 }, { "Full HD", 1600, 980 } }

local function read_size()
  size.file_w, size.file_h, size.version = jsfx_size()
end

-- The size the user chose last time, if an update has put the file back to the default
local function chosen_size()
  local s = r.GetExtState(EXT, "size")
  local w, h = s:match("^(%d+) (%d+)$")
  return tonumber(w), tonumber(h)
end

local function size_popover(x, y)
  local w, h = pt(440), pt(250)
  box(x, y, w, h, 0x121618, 0x2C3438, pt(8))
  local ix, cy = x + pt(12), y + pt(12)
  text("Opening size for new ReEQ2 windows", ix, cy, w, pt(18), 0, 0xDFE6E9, 14, true); cy = cy + pt(20)
  text("Windows you've already opened keep their own size.", ix, cy, w, pt(14), 0, 0x848F95, 12); cy = cy + pt(24)

  -- The size to scale, against a 1920 x 1080 screen
  local fw, fh = pt(150), pt(90)
  box(ix, cy, fw, fh, 0x0D1012, nil, pt(6))
  local k = math.min(fw / 1920, fh / 1080)
  local rw, rh = size.w * k, size.h * k
  rgb(0x0F2A33); gfx.rect(ix + (fw - rw) / 2, cy + (fh - rh) / 2, rw, rh, 1)
  rgb(0x5CC8EA); gfx.rect(ix + (fw - rw) / 2, cy + (fh - rh) / 2, rw, rh, 0)
  text(string.format("%d × %d", size.w, size.h), ix, cy + fh + pt(2), fw, pt(16), 1, 0x9AA5AA, 12)

  local px = ix + fw + pt(14)
  caption("PRESETS", px, cy)
  local bx, by = px, cy + pt(14)
  for _, p in ipairs(SIZE_PRESETS) do
    local bw = button_w(p[1])
    if bx + bw > x + w - pt(12) then bx = px; by = by + pt(28) end
    if button(p[1], bx, by, bw, pt(24), size.w == p[2] and size.h == p[3]) then size.w, size.h, size.msg = p[2], p[3], nil end
    bx = bx + bw + pt(5)
  end
  by = by + pt(32)
  if button(string.format("%d × %d  (type a size)", size.w, size.h), px, by, pt(200), pt(24)) then
    local ok, s = r.GetUserInputs("ReEQ2 window size", 2, "Width,Height", size.w .. "," .. size.h)
    if ok then
      local nw, nh = s:match("^%s*(%d+)%s*,%s*(%d+)%s*$")
      if nw then size.w, size.h, size.msg = tonumber(nw), tonumber(nh), nil end
    end
  end
  by = by + pt(30)
  local ow, oh = open_reeq2_size()
  if ow and button(string.format("Use the open ReEQ2's %d × %d", ow, oh), px, by, pt(200), pt(24)) then
    size.w, size.h, size.msg = ow, oh, nil
  end

  cy = y + h - pt(64)
  if size.msg then
    text(size.msg, ix, cy, w - pt(24), pt(28), 0, 0xE8875F, 12)
  else
    text("Saved into ReEQ2.jsfx. A ReEQ2 update puts it back to 922 × 564;", ix, cy, w - pt(24), pt(14), 0, 0x707A7F, 12)
    text("this offers to apply your size again.", ix, cy + pt(14), w - pt(24), pt(14), 0, 0x707A7F, 12)
  end
  cy = y + h - pt(34)
  local ax = x + w - pt(12)
  ax = ax - button_w("Apply")
  if button("Apply", ax, cy, button_w("Apply"), pt(24), true) then
    local ok, why = set_jsfx_size(size.w, size.h)
    if ok then read_size(); view = "main"; say(string.format("New ReEQ2 windows open at %d × %d.", size.w, size.h))
    else size.msg = why end
  end
  ax = ax - pt(6) - button_w("Cancel")
  if button("Cancel", ax, cy, button_w("Cancel"), pt(24)) then view = "main" end
  ax = ax - pt(6) - button_w("Default")
  if button("Default", ax, cy, button_w("Default"), pt(24)) then size.w, size.h, size.msg = DEFAULT_W, DEFAULT_H, nil end
  if mouse.press and not inside(x, y, w, h) and not mouse.capture then view = "main" end
end

----------------------------------------------------------------------------------------------------
-- Gallery: every theme in Themes/, drawn as ReEQ2 would show it; click one to try it
----------------------------------------------------------------------------------------------------

-- function(theme, img, w, h): a theme drawn into an image, set by the preview section further down
local preview_thumb

-- Thumbnail images: ids from THUMB_IMG, one per theme in the list. The cards are drawn on a canvas
-- (GALLERY_IMG) as tall as all of them, and the view shows the part scrolled to.
local THUMB_IMG, GALLERY_IMG = 200, 199
local gallery_scroll = 0  -- pixels

local function gallery_view(x, y, w, h)
  if #gallery == 0 then
    text("No themes yet. Save one with Save as, and it appears here.", x, y, w, pt(20), 0, 0x848F95, 13)
    return
  end
  local bar = pt(10)                 -- the scrollbar's lane
  local cols, gap = 4, pt(10)
  local vw = w - bar - pt(6)
  local cw = math.floor((vw - gap * (cols - 1)) / cols)
  local tw = cw - pt(12)
  local th = math.floor(tw * DEFAULT_H / DEFAULT_W)
  local ch = th + pt(36)
  local rows = math.floor((#gallery + cols - 1) / cols)
  local total = rows * (ch + gap) - gap
  local over = inside(x, y, w, h)

  -- Scrolling: the wheel, or dragging the scrollbar
  local range = math.max(0, total - h)
  if over and mouse.wheel ~= 0 then gallery_scroll = gallery_scroll - mouse.wheel * pt(80) end
  local tx, tlen = x + w - bar, math.max(pt(30), h * math.min(1, h / total))
  if range > 0 and inside(tx, y, bar, h) and mouse.press and not mouse.capture then mouse.capture = "gallery" end
  if mouse.capture == "gallery" and range > 0 then
    gallery_scroll = (mouse.y - y - tlen / 2) / (h - tlen) * range
  end
  gallery_scroll = math.max(0, math.min(gallery_scroll, range))

  -- One thumbnail per frame, so opening the gallery never stalls REAPER
  for i, t in ipairs(gallery) do
    if t.thumb_w ~= tw and preview_thumb then
      preview_thumb(t, THUMB_IMG + i - 1, tw, th)
      t.thumb_w = tw
      break
    end
  end

  -- The cards, on the canvas; the mouse is mapped onto it
  local mx, my = mouse.x - x, mouse.y - y + gallery_scroll
  local dest = gfx.dest
  gfx.setimgdim(GALLERY_IMG, vw, total)
  gfx.dest = GALLERY_IMG
  rgb(0x0D1012); gfx.rect(0, 0, vw, total, 1)
  local picked
  for i, t in ipairs(gallery) do
    local gx = ((i - 1) % cols) * (cw + gap)
    local gy = math.floor((i - 1) / cols) * (ch + gap)
    -- Only cards in view are drawn
    if gy + ch > gallery_scroll and gy < gallery_scroll + h then
      local hov = over and not mouse.capture and mx >= gx and mx < gx + cw and my >= gy and my < gy + ch
      box(gx, gy, cw, ch, hov and 0x1A1F22 or 0x121618, hov and 0x5CC8EA or 0x2C3438, pt(8))
      if t.thumb_w == tw then
        gfx.a = 1
        gfx.blit(THUMB_IMG + i - 1, 1, 0, 0, 0, tw, th, gx + pt(6), gy + pt(6), tw, th)
      else
        box(gx + pt(6), gy + pt(6), tw, th, 0x0D1012, nil, pt(4))
        text("Drawing...", gx + pt(6), gy + pt(6), tw, th, 1, 0x707A7F, 12)
      end
      text(t.name, gx + pt(10), gy + th + pt(8), cw - pt(20), pt(24), 0, 0xDFE6E9, 13)
      if hov and mouse.press then picked = t end
    end
  end
  gfx.dest = dest
  gfx.a = 1
  gfx.blit(GALLERY_IMG, 1, 0, 0, gallery_scroll, vw, h, x, y, vw, h)

  if range > 0 then
    box(tx, y, bar, h, 0x121618, nil, pt(5))
    box(tx, y + (h - tlen) * gallery_scroll / range, bar, tlen, mouse.capture == "gallery" and 0x5CC8EA or 0x3A4449, nil, pt(5))
  end

  if picked then
    load_into_editor(picked)
    view = "main"
    say("Trying " .. picked.name .. ". Revert goes back to the saved theme.")
  end
end

----------------------------------------------------------------------------------------------------
-- The ReEQ2 preview (a translated copy of ReEQ2's drawing, further down) and click-to-pick
----------------------------------------------------------------------------------------------------

-- What the preview shows of the analyser: "off", "fill", "line" or "heat", the pre-EQ line, the second
-- trace (Side or Right); and band 3 heard on its own (listen), and band 3's ghost spectrum (ghost)
local an = { mode = "fill", pre = true, second = true, listen = false, ghost = false }

local preview_draw  -- function(x, y, w, h), set by the preview section
local preview_pick  -- function(x, y, w, h) -> token key under the mouse, or nil

----------------------------------------------------------------------------------------------------
-- The preview: ReEQ2's own drawing, translated from ReEQ2 2.2.0 (ReEQ2.jsfx @gfx, spectrum.jsfx-inc
-- and ivantsov_filter.jsfx-inc) and drawn on fixed example state under ReEQ2's names. Each function
-- names its source: a change to ReEQ2's drawing is made here too, and PREVIEW_FROM moves with it.
--
-- The scene is drawn at ReEQ2's default size (922 x 564 pt at the editor's scale S) into an offscreen
-- image, again only when the theme, the analyser options or S change, and blitted into the preview.
-- Click-to-pick draws the same scene into a second image with every colour replaced by its token's ID
-- colour at full opacity, and reads the pixel under the mouse.
----------------------------------------------------------------------------------------------------

local function preview_module()
  local floor, ceil, min, max, abs, sqrt = math.floor, math.ceil, math.min, math.max, math.abs, math.sqrt
  local exp, log, sin, cos, PI = math.exp, math.log, math.sin, math.cos, math.pi
  local function log10(x) return log(x, 10) end
  local BOLD = string.byte("b")

  -- Token ids under ReEQ2's names (T.TEXT_SECONDARY is T_TEXT_SECONDARY), and the palette as ReEQ2
  -- holds it (pal_set()): per id r, g, b (0..255) and alpha, from the theme being edited
  local T = {}
  for _, t in ipairs(TOKENS) do T[t.key:upper()] = t.id end
  local Pal = {}
  local function pal_load()
    for _, t in ipairs(TOKENS) do
      local c = theme.c[t.key]
      local cr, cg, cb = unpack_hex(c.hex)
      Pal[t.id] = { cr, cg, cb, c.a }
    end
  end

  -- Pick mode: every token draws in its own ID colour at full opacity. r steps by 3 per id; g and b
  -- are checks, so a blend of two IDs at an antialiased edge reads as no token.
  local PICK, PICK_KEY = {}, {}
  for _, t in ipairs(TOKENS) do
    local n = t.id + 1
    local cr, cg, cb = n * 3, (n * 37) % 251, (n * 101) % 241
    PICK[t.id] = { cr / 255, cg / 255, cb / 255 }
    PICK_KEY[cr * 65536 + cg * 256 + cb] = t.key
  end
  local picking = false

  -- An alpha the drawing sets directly: full in pick mode
  local function A(a)
    if picking then return 1 end
    return a
  end

  local function pick_set(t)
    local c = PICK[t]
    gfx.r, gfx.g, gfx.b, gfx.a = c[1], c[2], c[3], 1
  end

  ------------------------------------------------------------------------------------------------
  -- Example state, under ReEQ2's names: four bands in Mid/Side mode at +-18 dB, band 3 selected and
  -- dynamic. The mouse is over the window (ui_fade 1) but over nothing in it; no popup is open.
  ------------------------------------------------------------------------------------------------

  local NUM_BANDS = 16
  local BAND_STATE_OFF, BAND_STATE_DISABLED, BAND_STATE_ENABLED = 0, 1, 2
  local FILTER_PEAK, FILTER_LOW_CUT, FILTER_LOW_CUT_BUTTERWORTH, FILTER_LOW_SHELF = 0, 1, 2, 3
  local FILTER_HIGH_SHELF, FILTER_HIGH_CUT, FILTER_HIGH_CUT_BUTTERWORTH, FILTER_NOTCH, FILTER_BAND_PASS = 4, 5, 6, 7, 8
  local FILTER_TILT_SHELF, FILTER_PULTEC_LOW_SHELF, FILTER_ALL_PASS = 9, 10, 11
  local FILTER_LOW_CUT_ANALOG, FILTER_HIGH_CUT_ANALOG = 12, 13
  local MIN_FREQ, MAX_FREQ = 10, 30000
  local FREQ_LOG_MAX = log(MAX_FREQ / MIN_FREQ)
  -- Db_Range 2: +-18 dB in 6 dB steps
  local DB_EQ_RANGE, DB_EQ_RANGE_STEPS = 18, 6

  local Band_Enabled, Band_Group, Band_Type, Band_Frequency, Band_Gain, Band_Q, Band_Slope = {}, {}, {}, {}, {}, {}, {}
  local Band_Dyn_On, Band_Dyn_Thresh, Band_Dyn_Ratio, Band_Dynamic_Range = {}, {}, {}, {}
  local Band_Dyn_Attack, Band_Dyn_Release, Band_Dyn_Auto, Band_Dyn_Source, Band_Dyn_Link = {}, {}, {}, {}, {}
  local Band_Dyn_Gain, Band_Dyn_Level, Band_Selected = {}, {}, {}
  local Band_Dyn_DetFreq, Band_Dyn_DetWidth = {}, {}
  local Band_Red, Band_Green, Band_Blue = {}, {}, {}
  for b = 0, NUM_BANDS - 1 do
    -- The sliders' defaults (an unused band is an off 0 dB bell) and band_dyn_defaults()
    Band_Enabled[b] = BAND_STATE_OFF; Band_Group[b] = 0; Band_Type[b] = FILTER_PEAK; Band_Frequency[b] = 1000
    Band_Gain[b] = 0; Band_Q[b] = 0.7071; Band_Slope[b] = 0; Band_Selected[b] = 0
    Band_Dyn_On[b] = 0; Band_Dyn_Thresh[b] = -24; Band_Dyn_Ratio[b] = 4; Band_Dynamic_Range[b] = -6
    Band_Dyn_Attack[b] = 5; Band_Dyn_Release[b] = 80; Band_Dyn_Auto[b] = 1; Band_Dyn_Source[b] = 0
    Band_Dyn_Link[b] = 1; Band_Dyn_Gain[b] = 0; Band_Dyn_Level[b] = -150
    Band_Dyn_DetFreq[b] = 1000; Band_Dyn_DetWidth[b] = 0
    Band_Red[b], Band_Green[b], Band_Blue[b] = 0, 0, 0
  end
  local function example_band(b, t, f, g, slope)
    Band_Enabled[b] = BAND_STATE_ENABLED; Band_Type[b] = t; Band_Frequency[b] = f; Band_Gain[b] = g; Band_Slope[b] = slope
  end
  -- All four in Stereo placement, Q 0.71
  example_band(0, FILTER_LOW_CUT_BUTTERWORTH, 18.5, 0, 0)     -- slope 0: 6 dB/oct
  example_band(1, FILTER_PEAK, 101, -4, 0)
  example_band(2, FILTER_PEAK, 690, 5, 0)
  example_band(3, FILTER_HIGH_SHELF, 7000, -3, 0)
  -- Band 3: dynamic, auto timing, detecting its own input (linked), working: its level -26.5 dB and
  -- 2.5 dB of gain reduction, so its static curve, live gain and meter show
  Band_Dyn_On[2] = 1; Band_Dyn_Thresh[2] = -30; Band_Dyn_Ratio[2] = 4; Band_Dynamic_Range[2] = -6
  Band_Dyn_Gain[2] = -2.5; Band_Dyn_Level[2] = -26.5
  -- Its detector node, used when the editor's Ghost button unlinks it (dyn_unlink() would start it at
  -- the band; this one has been dragged up to 2.4 kHz, two octaves wide)
  Band_Dyn_DetFreq[2] = 2400; Band_Dyn_DetWidth[2] = 2
  local selected_node = 2
  Band_Selected[2] = 1
  -- Listening: listen_node is the band heard on its own (its solo button; the editor's Listen button
  -- sets it to band 3), do_listen the Shift-drag listen (never on here). The ghost spectrum follows
  -- Ghost_Band, set in render() as ReEQ2's main section sets it.
  local node_hover, listen_node, Dyn_Listen, ui_popup = -1, -1, -1, 0
  local do_listen, listen_group, listen_gain, Ghost_Band = 0, 0, 1, -1
  -- The sample rate the analyser and the audio filters run at
  local srate = 48000
  -- glow_node_selection_halo() pulses the selection ring between 0.4 and 0.8; drawn at 0.8, its start
  local band_selected_circle_alpha = 0.8
  local Scale, PanelEnabled = 100, 1
  -- From the editor's analyser buttons before each render (Display_Mode: 0 Fill, 1 Line, 2 off, 3 Heat;
  -- SPEC_MODE 3 Mid / Side, 1 Mid)
  local Display_Mode, Show_PreEQ, SPEC_MODE = 0, 1, 3

  -- The layout, set by layout() for the render size
  local retina, gfx_w, gfx_h = 1, DEFAULT_W, DEFAULT_H
  local HIDPI, actual_width, actual_height = false, DEFAULT_W, DEFAULT_H
  local compact_width, compact_height, very_compact_width, very_compact_height = false, false, false, false
  local HEADER_H, TOP_MARGIN, BOTTOM_MARGIN, RAISED_BOTTOM, ENABLE_RAISED_BOTTOM = 0, 0, 0, 0, 0
  local LEFT_MARGIN, RIGHT_MARGIN, ShowPanel = 0, 0, 0
  local panel_x, panel_y, panel_w, panel_h, ui_dyn_panel = 0, 0, 0, 0, false
  local ui_th1, ui_mix = 0, 0
  local ui_dbb_lab, ui_dbb_cy = "", 0

  -- Font slots, as ReEQ2's (the credits card's logo fonts are left out)
  local FONT_BASE, FONT_CAP, FONT_BODY, FONT_BODY_B, FONT_EMPH = 1, 3, 5, 6, 7
  local FONT_DISPLAY, FONT_DISPLAY_B, FONT_NODE, FONT_SUP = 8, 9, 10, 11

  ------------------------------------------------------------------------------------------------
  -- Theme and drawing helpers
  ------------------------------------------------------------------------------------------------

  -- from ReEQ2 2.1.0: rscale()
  local function rscale(v1, v2)
    local s = max(retina, 1)
    if s <= 2 then return v1 + (v2 - v1) * (s - 1) end
    return v2 * s * 0.5
  end

  -- from ReEQ2 2.1.0: ui_pt()
  local function ui_pt(v)
    return v * max(retina, 1)
  end

  -- from ReEQ2 2.1.0: ui_font()
  local function ui_font(slot, pt, flags)
    gfx.setfont(slot, "Arial", floor(ui_pt(pt) + 0.5), flags)
  end

  -- from ReEQ2 2.1.0: ui_col() (faded toward T_TILE by ui_mix)
  local function ui_col(t)
    if picking then pick_set(t); return end
    local p, d = Pal[t], Pal[T.TILE]
    gfx.r = (p[1] + (d[1] - p[1]) * ui_mix) / 255
    gfx.g = (p[2] + (d[2] - p[2]) * ui_mix) / 255
    gfx.b = (p[3] + (d[3] - p[3]) * ui_mix) / 255
    gfx.a = p[4]
  end

  -- from ReEQ2 2.1.0: ui_col_a()
  local function ui_col_a(t, a)
    ui_col(t)
    gfx.a = A(a * Pal[t][4])
  end

  -- from ReEQ2 2.1.0: ui_cola() (never faded)
  local function ui_cola(t, a)
    if picking then pick_set(t); return end
    local p = Pal[t]
    gfx.r, gfx.g, gfx.b = p[1] / 255, p[2] / 255, p[3] / 255
    gfx.a = a * p[4]
  end

  -- from ReEQ2 2.1.0: ui_col_mix() (picks as t0 below halfway, t1 above)
  local function ui_col_mix(t0, t1, f, a)
    if picking then pick_set(f < 0.5 and t0 or t1); return end
    local p, q, d = Pal[t0], Pal[t1], Pal[T.TILE]
    local v = p[1] + (q[1] - p[1]) * f; gfx.r = (v + (d[1] - v) * ui_mix) / 255
    v = p[2] + (q[2] - p[2]) * f; gfx.g = (v + (d[2] - v) * ui_mix) / 255
    v = p[3] + (q[3] - p[3]) * f; gfx.b = (v + (d[3] - v) * ui_mix) / 255
    gfx.a = a * p[4]
  end

  -- from ReEQ2 2.1.0: ui_band_col()
  local function ui_band_col(b)
    ui_col(T.BAND1 + b % 8)
  end

  -- gfx.gradrect; in the pick image a rect in token t's ID colour (the current colour is kept)
  local function gradrect(t, x, y, w, h, r, g, b, a, drdx, dgdx, dbdx, dadx, drdy, dgdy, dbdy, dady)
    if picking then
      local r0, g0, b0, a0 = gfx.r, gfx.g, gfx.b, gfx.a
      pick_set(t)
      gfx.rect(x, y, w, h, 1)
      gfx.r, gfx.g, gfx.b, gfx.a = r0, g0, b0, a0
    else
      gfx.gradrect(x, y, w, h, r, g, b, a, drdx, dgdx, dbdx, dadx, drdy, dgdy, dbdy, dady)
    end
  end

  -- from ReEQ2 2.1.0: ui_fill_rrect()
  local function ui_fill_rrect(x, y, w, h, r)
    x = floor(x); y = floor(y); w = floor(w); h = floor(h)
    r = floor(min(r, min(w, h) * 0.5))
    local a0 = gfx.a
    gfx.rect(x, y + r, w, h - 2 * r, 1)
    for i = 0, r - 1 do
      local dy = r - i - 0.5
      local dx = r - sqrt(max(r * r - dy * dy, 0))
      local xi = ceil(dx)
      local fr = xi - dx
      gfx.rect(x + xi, y + i, w - 2 * xi, 1, 1)
      gfx.rect(x + xi, y + h - 1 - i, w - 2 * xi, 1, 1)
      if fr > 0.02 then
        gfx.a = A(a0 * fr)
        gfx.rect(x + xi - 1, y + i, 1, 1, 1)
        gfx.rect(x + w - xi, y + i, 1, 1, 1)
        gfx.rect(x + xi - 1, y + h - 1 - i, 1, 1, 1)
        gfx.rect(x + w - xi, y + h - 1 - i, 1, 1, 1)
        gfx.a = a0
      end
    end
  end

  -- from ReEQ2 2.1.0: ui_box()
  local function ui_box(x, y, w, h, r, tf, fa, tb)
    x = floor(x); y = floor(y); w = floor(w); h = floor(h)
    ui_cola(tf, fa)
    ui_fill_rrect(x, y, w, h, r)
    ui_cola(tb, 1)
    gfx.roundrect(x, y, w - 1, h - 1, r, 1)
  end

  -- from ReEQ2 2.1.0: ui_text_c()
  local function ui_text_c(x, y, w, h, s)
    gfx.x = floor(x); gfx.y = floor(y)
    gfx.drawstr(s, 1 + 4, floor(x + w), floor(y + h))
  end

  -- from ReEQ2 2.1.0: ui_text_l()
  local function ui_text_l(x, y, h, s)
    gfx.x = floor(x); gfx.y = floor(y)
    gfx.drawstr(s, 4 + 256, floor(x + gfx_w), floor(y + h))
  end

  -- from ReEQ2 2.1.0: ui_text_at()
  local function ui_text_at(cx, cy, s)
    local w, h = gfx.measurestr(s)
    gfx.x = floor(cx - w * 0.5 + 0.5); gfx.y = floor(cy - h * 0.5 + 0.5)
    gfx.drawstr(s)
  end

  -- from ReEQ2 2.1.0: ui_text_r()
  local function ui_text_r(x, y, w, h, s)
    gfx.x = floor(x); gfx.y = floor(y)
    gfx.drawstr(s, 2 + 4, floor(x + w), floor(y + h))
  end

  -- from ReEQ2 2.1.0: ui_text_w()
  local function ui_text_w(s)
    local w = gfx.measurestr(s)
    return w
  end

  -- from ReEQ2 2.1.0: ui_thick_line()
  local function ui_thick_line(x1, y1, x2, y2, w)
    local dx, dy = x2 - x1, y2 - y1
    local l = max(sqrt(dx * dx + dy * dy), 0.001)
    local nx, ny = -dy / l, dx / l
    local o = -(w - 1) * 0.5
    repeat
      gfx.line(x1 + nx * o, y1 + ny * o, x2 + nx * o, y2 + ny * o, 1)
      o = o + 0.75
    until not (o <= (w - 1) * 0.5 + 0.01)
  end

  -- from ReEQ2 2.1.0: ui_thick_arc()
  local function ui_thick_arc(cx, cy, r, a0, a1, w)
    local o = -(w - 1) * 0.5
    repeat
      gfx.arc(cx, cy, r + o, a0, a1, 1)
      o = o + 0.5
    until not (o <= (w - 1) * 0.5 + 0.01)
  end

  -- from ReEQ2 2.1.0: ui_chevron()
  local function ui_chevron(cx, cy, s, dir)
    gfx.triangle(cx - s, cy - s * 0.5 * dir, cx + s, cy - s * 0.5 * dir, cx, cy + s * 0.5 * dir)
  end

  -- from ReEQ2 2.1.0: ui_fmt_db()
  local function ui_fmt_db(v)
    if abs(v) < 0.05 then return "0.0" end
    if v > 0 then return string.format("+%.1f", v) end
    return string.format("−%.1f", -v)
  end

  -- from ReEQ2 2.1.0: ui_is_cut()
  local function ui_is_cut(t)
    return t == FILTER_LOW_CUT or t == FILTER_LOW_CUT_BUTTERWORTH or t == FILTER_HIGH_CUT or t == FILTER_HIGH_CUT_BUTTERWORTH
  end

  -- from ReEQ2 2.1.0: band_dyn_capable()
  local function band_dyn_capable(t)
    return t == FILTER_PEAK or t == FILTER_LOW_SHELF or t == FILTER_HIGH_SHELF
  end

  -- from ReEQ2 2.1.0: ui_slope_db(), ui_slope_index()
  local function ui_slope_db(i)
    if i < 6 then return 6 * (i + 1) end
    return i == 6 and 48 or i == 7 and 72 or i == 8 and 96 or 120
  end

  local function ui_slope_index(k)
    local db = 6 * (k + 1)
    local best = 0
    for i = 1, 9 do
      if abs(ui_slope_db(i) - db) < abs(ui_slope_db(best) - db) then best = i end
    end
    return best
  end

  ------------------------------------------------------------------------------------------------
  -- Filters: the shapes, the analogue magnitude the curves are drawn from, and the digital magnitude
  -- the audio (and so the analyser) gets
  ------------------------------------------------------------------------------------------------

  -- from ivantsov_filter.jsfx-inc. A filter here is at rest (as ivf_set_to_target() leaves it): each
  -- second order section keeps its analogue prototype (aT, aF, aZ, aG) and its coefficients (P, Q, D,
  -- E, C), the first order section likewise (aT, aF; P, B, C), and how many run. A filter's methods are
  -- the include's functions under their names, so filter.ivf_bell(...) in EEL is filter:ivf_bell(...).
  local ivf_new, band_set_filter, ivf_set_to_target, ivf_analog_magnitude, ivf = (function()
    local methods = {}

    -- ivf_init(): idle, at rest
    local function ivf_new()
      local f = { s = {}, op = { aT = 0, aF = 1000, P = 1, B = 1, C = 1 }, n_run = 0, n_target = 0, op_run = false, op_target = false }
      return setmetatable(f, { __index = methods })
    end

    -- ivf_bwtoq(), ivf_qtobw()
    local function ivf_bwtoq(bw)
      local x = exp(0.5 * log(2) * bw)
      return x / (x * x - 1)
    end

    local function ivf_qtobw(q)
      local x = 0.5 / q
      return 2 / log(2) * log(x + sqrt(x * x + 1))
    end

    -- ivf_sec_calc(): the analogue section, and the section's coefficients (its targets, which
    -- ivf_set_to_target() makes current)
    local function ivf_sec_calc(sec, t, fc, zeta, gn)
      sec.aT, sec.aF, sec.aZ, sec.aG = t, fc, zeta, gn

      -- Cutoff warp: sigma correction up to Nyquist, plain bilinear above
      local w = srate / (PI * fc)
      local s = 2 / PI
      if fc < srate * 0.5 then
        local x = PI * fc / srate
        local r = cos(x) / sin(x)
        s = sqrt(max(w * w - r * r, 0))
      end
      local ss = s * s

      -- Poles
      local zp = t == 7 and zeta / gn or zeta
      local tt = t == 4 and w * w * gn or t == 3 and w * w / gn or w * w
      local k = tt * (2 * zp * zp - 1)
      local v = sqrt(tt * tt + ss * (2 * k + ss))
      k = k + ss
      local b0 = 2 / (1 + sqrt(2 * (k + v)) + v)
      local b1 = sqrt(v)

      -- Zeros
      local b2, b3
      if t == 3 or t == 4 or t == 7 then
        local zz = t == 7 and zeta * gn or zp
        tt = t == 4 and w * w / gn or t == 3 and w * w * gn or w * w
        local ka = tt * (2 * zz * zz - 1)
        local va = sqrt(tt * tt + ss * (2 * ka + ss))
        ka = ka + ss
        b2 = va / b1
        b3 = (1 + sqrt(2 * (ka + va)) + va) * 0.5
      elseif t == 0 then
        b2 = w * w / b1
        b3 = w * w * 0.5
      elseif t == 1 then
        b2 = ss / b1
        b3 = (1 + s) * (1 + s) * 0.5
      elseif t == 2 then
        b2 = b1
        b3 = (1 - sqrt(2 * (k + v)) + v) * 0.5
      elseif t == 5 then
        b2 = 2 * w * zeta * s / b1
        b3 = w * zeta * (1 + s)
      else
        b2 = (w * w - ss) / b1
        b3 = (1 + w * w - ss) * 0.5
      end

      -- The low shelf's level is its output gain
      local og = t == 4 and gn * gn or 1

      sec.P = b0
      sec.Q = b0 * b1 * b1
      sec.D = b0 * b3 * og
      sec.E = b2 * og / b1
      sec.C = (t == 0 or t == 5) and 0 or og
    end

    -- ivf_put(): section i of the design
    local function ivf_put(f, i, t, fc, zeta, gn)
      local sec = {}
      ivf_sec_calc(sec, t, fc, zeta, gn)
      f.s[i] = sec
    end

    -- ivf_op_calc()
    local function ivf_op_calc(f, t, fc)
      local op = f.op
      op.aT = t; op.aF = fc
      local w = srate / (PI * fc)
      local s = 2 / PI
      if fc < srate * 0.5 then
        local x = PI * fc / srate
        local r = cos(x) / sin(x)
        s = sqrt(max(w * w - r * r, 0))
      end
      op.P = 2 / (1 + sqrt(w * w + s * s))
      op.B = op.P * (t == 1 and (1 + s) * 0.5 or w * 0.5)
      op.C = t == 1 and 1 or 0
    end

    -- ivf_commit()
    local function ivf_commit(f, n, op_on)
      f.n_run = max(f.n_run, n)
      f.n_target = n
      f.op_run = f.op_run or op_on
      f.op_target = op_on
    end

    -- ivf_set_to_target()
    local function ivf_set_to_target(f)
      f.n_run = f.n_target
      f.op_run = f.op_target
    end

    -- ivf_put_butterworth()
    local function ivf_put_butterworth(f, i, t, fc, order)
      local odd = order % 2
      for j = 0, floor(order / 2) - 1 do
        ivf_put(f, i, t, fc, cos(PI * (2 * (j + odd) + 1 - odd) / (2 * order)), 1)
        i = i + 1
      end
      return i
    end

    -- ivf_bell(), ivf_low_shelf(), ivf_high_shelf()
    local function ivf_bell(f, freq, q, db)
      if db ~= 0 then ivf_put(f, 1, 7, freq, 0.5 / q, 10 ^ (db / 40)) end
      ivf_commit(f, db ~= 0 and 1 or 0, false)
    end

    local function ivf_low_shelf(f, freq, q, db)
      if db ~= 0 then ivf_put(f, 1, 4, freq, 0.5 / q, 10 ^ (db / 40)) end
      ivf_commit(f, db ~= 0 and 1 or 0, false)
    end

    local function ivf_high_shelf(f, freq, q, db)
      if db ~= 0 then ivf_put(f, 1, 3, freq, 0.5 / q, 10 ^ (db / 40)) end
      ivf_commit(f, db ~= 0 and 1 or 0, false)
    end

    -- ivf_notch(), ivf_band_pass(), ivf_all_pass()
    local function ivf_notch(f, freq, q)
      ivf_put(f, 1, 6, freq, 0.5 / q, 1)
      ivf_commit(f, 1, false)
    end

    local function ivf_band_pass(f, freq, q)
      ivf_put(f, 1, 5, freq, 0.5 / q, 1)
      ivf_commit(f, 1, false)
    end

    local function ivf_all_pass(f, freq, q)
      ivf_put(f, 1, 2, freq, 0.5 / q, 1)
      ivf_commit(f, 1, false)
    end

    -- ivf_cut(), ivf_low_cut(), ivf_high_cut(): every second order section has the band's Q, an even
    -- slope adds the first order section
    local function ivf_cut(f, t, freq, q, slope)
      local n = floor((slope + 1) / 2)
      for i = 1, n do ivf_put(f, i, t, freq, 0.5 / q, 1) end
      if slope % 2 == 0 then ivf_op_calc(f, t, freq) end
      ivf_commit(f, n, slope % 2 == 0)
    end

    local function ivf_low_cut(f, freq, q, slope) ivf_cut(f, 0, freq, q, slope) end
    local function ivf_high_cut(f, freq, q, slope) ivf_cut(f, 1, freq, q, slope) end

    -- ivf_cut_r(): a Butterworth cut's resonance for band Q q, the factor its highest-Q section's Q is
    -- multiplied by (1 at Q 0.7071; the section kept at Q 30 or less)
    local function ivf_cut_r(q, order)
      local m, odd = floor(order / 2), order % 2
      if m < 1 or math.abs(q - 0.7071) < 0.0005 then return 1 end
      return math.min(q * math.sqrt(2), 60 * cos(PI * (2 * (m - 1 + odd) + 1 - odd) / (2 * order)))
    end

    -- ivf_cut_bw(), ivf_low_cut_bw(), ivf_high_cut_bw(), ivf_low_cut_bwq(), ivf_high_cut_bwq(): the
    -- highest-Q section's Q multiplied by r
    local function ivf_cut_bw(f, t, freq, slope, r)
      local order = slope + 1
      local odd = order % 2
      local n = ivf_put_butterworth(f, 1, t, freq, order) - 1
      if r ~= 1 and n >= 1 then
        ivf_put(f, n, t, freq, cos(PI * (2 * (n - 1 + odd) + 1 - odd) / (2 * order)) / r, 1)
      end
      if slope % 2 == 0 then ivf_op_calc(f, t, freq) end
      ivf_commit(f, floor((slope + 1) / 2), slope % 2 == 0)
    end

    local function ivf_low_cut_bw(f, freq, slope) ivf_cut_bw(f, 0, freq, slope, 1) end
    local function ivf_high_cut_bw(f, freq, slope) ivf_cut_bw(f, 1, freq, slope, 1) end
    local function ivf_low_cut_bwq(f, freq, q, slope) ivf_cut_bw(f, 0, freq, slope, ivf_cut_r(q, slope + 1)) end
    local function ivf_high_cut_bwq(f, freq, q, slope) ivf_cut_bw(f, 1, freq, slope, ivf_cut_r(q, slope + 1)) end

    -- ivf_tilt()
    local function ivf_tilt(f, freq, q, db)
      if db ~= 0 then
        ivf_put(f, 1, 3, freq, 0.5 / q, 10 ^ (db / 40))
        ivf_put(f, 2, 4, freq, 0.5 / q, 10 ^ (-db / 40))
      end
      ivf_commit(f, db ~= 0 and 2 or 0, false)
    end

    -- ivf_pultec_low()
    local function ivf_pultec_low(f, freq, q, db)
      freq = freq * 1.5
      local amm = min(max(db, 0), 10) / 10
      local cut = (q / 40) * 10 * amm
      if db ~= 0 then
        ivf_put(f, 1, 4, freq, 0.5 / 0.701, 10 ^ (db / 40))
        ivf_put(f, 2, 7, freq, 0.5 / 0.701, 10 ^ (-cut / 40))
      end
      ivf_commit(f, db ~= 0 and 2 or 0, false)
    end

    -- ivf_vintage_low()
    local function ivf_vintage_low(f, freq, q, db)
      ivf_put(f, 1, 4, freq * 1.25, 0.5 / 0.701, 10 ^ (db / 40))
      ivf_op_calc(f, 0, freq)
      ivf_commit(f, 1, true)
    end

    -- ivf_vintage_high()
    local function ivf_vintage_high(f, freq, q, db)
      local cutoff
      if db > 0 then
        cutoff = 22000
      else
        local t = 1 - (-max(db, -12) / 12)
        cutoff = freq + ((freq * 4.25 - freq) * t)
      end
      cutoff = min(cutoff, 22040)
      ivf_put(f, 1, 3, freq, 0.5 / 0.701, 10 ^ (db / 40))
      ivf_put(f, 2, 1, cutoff, 0.5 / 0.701, 1)
      ivf_commit(f, 2, false)
    end

    -- ivf_bypass()
    local function ivf_bypass(f)
      ivf_commit(f, 0, false)
    end

    -- ivf_listen_bell(), ivf_listen_notch(): a bell or notch between 24dB/oct Butterworth cuts
    local function ivf_listen_bell(f, leftfreq, rightfreq, bellfreq, bellq, belldb)
      leftfreq = max(leftfreq, 10)
      bellfreq = min(max(bellfreq, 10), 30000)
      rightfreq = min(rightfreq, 30000)
      ivf_put(f, 1, 7, bellfreq, 0.5 / bellq, 10 ^ (belldb / 40))
      local i = ivf_put_butterworth(f, 2, 0, leftfreq, 4)
      ivf_put_butterworth(f, i, 1, rightfreq, 4)
      ivf_commit(f, 5, false)
    end

    local function ivf_listen_notch(f, leftfreq, rightfreq, notchfreq, notchq)
      leftfreq = max(leftfreq, 10)
      notchfreq = min(max(notchfreq, 10), 30000)
      rightfreq = min(rightfreq, 30000)
      ivf_put(f, 1, 6, notchfreq, 0.5 / notchq, 1)
      local i = ivf_put_butterworth(f, 2, 0, leftfreq, 4)
      ivf_put_butterworth(f, i, 1, rightfreq, 4)
      ivf_commit(f, 5, false)
    end

    -- ivf_sec_mag(), ivf_op_mag(): a section's magnitude from sin^2 and cos^2 of half the angle
    local function ivf_sec_mag(sec, sn, cs)
      local P, Q, D, E, C = sec.P, sec.Q, sec.D, sec.E, sec.C
      local a, b = C * P - 2 * D * sn, 2 * D * cs - E * Q
      local c, d = P - 2 * sn, 2 * cs - Q
      return sqrt((cs * a * a + sn * b * b) / (cs * c * c + sn * d * d))
    end

    local function ivf_op_mag(op, sn, cs)
      local P, B, C = op.P, op.B, op.C
      local a, c = C * P - 2 * B * sn, P - 2 * sn
      return sqrt((a * a + 4 * B * B * sn * cs) / (c * c + 4 * sn * cs))
    end

    -- ivf_magnitude(): the digital response, holding its Nyquist value above Nyquist
    local function ivf_magnitude(f, freq)
      local x = PI * min(freq, srate * 0.5) / srate
      local sn, cs = sin(x) ^ 2, cos(x) ^ 2
      local m = 1
      for i = 1, f.n_run do m = m * ivf_sec_mag(f.s[i], sn, cs) end
      if f.op_run then m = m * ivf_op_mag(f.op, sn, cs) end
      return m
    end

    -- ivf_sec_amag()
    local function ivf_sec_amag(sec, f)
      local aT, aZ, aG = sec.aT, sec.aZ, sec.aG
      local o = f / sec.aF
      local o2 = o * o
      local dr, di = 1 - o2, 2 * aZ * o
      local nr, ni = 1, 0
      if aT == 0 then
        nr = -o2
      elseif aT == 2 then
        nr = dr; ni = -di
      elseif aT == 3 then
        local r = sqrt(aG); dr = aG - o2; di = 2 * aZ * r * o; nr = aG * (1 - aG * o2); ni = aG * di
      elseif aT == 4 then
        local r = sqrt(aG); dr = 1 - aG * o2; di = 2 * aZ * r * o; nr = aG * (aG - o2); ni = aG * di
      elseif aT == 5 then
        nr = 0; ni = di
      elseif aT == 6 then
        nr = dr
      elseif aT == 7 then
        nr = dr; ni = di * aG; di = di / aG
      end
      return sqrt((nr * nr + ni * ni) / (dr * dr + di * di))
    end

    -- ivf_op_amag()
    local function ivf_op_amag(op, f)
      local o = f / op.aF
      if op.aT == 1 then return 1 / sqrt(1 + o * o) end
      return o / sqrt(1 + o * o)
    end

    -- ivf_analog_magnitude()
    local function ivf_analog_magnitude(f, freq)
      local m = 1
      for i = 1, f.n_run do m = m * ivf_sec_amag(f.s[i], freq) end
      if f.op_run then m = m * ivf_op_amag(f.op, freq) end
      return m
    end

    -- from ReEQ2 2.1.0: band_set_filter()
    local function band_set_filter(f, t, freq, g, qval, slope)
      if t == 0 then ivf_bell(f, freq, qval, g)
      elseif t == 1 then ivf_low_cut(f, freq, qval, slope)
      elseif t == 2 then ivf_low_cut_bwq(f, freq, qval, slope)
      elseif t == 3 then ivf_low_shelf(f, freq, qval, g)
      elseif t == 4 then ivf_high_shelf(f, freq, qval, g)
      elseif t == 5 then ivf_high_cut(f, freq, qval, slope)
      elseif t == 6 then ivf_high_cut_bwq(f, freq, qval, slope)
      elseif t == 7 then ivf_notch(f, freq, qval)
      elseif t == 8 then ivf_band_pass(f, freq, qval)
      elseif t == 9 then ivf_tilt(f, freq, qval, g)
      elseif t == 10 then ivf_pultec_low(f, freq, qval, g)
      elseif t == 11 then ivf_all_pass(f, freq, qval)
      elseif t == 12 then ivf_vintage_low(f, freq, qval, g)
      elseif t == 13 then ivf_vintage_high(f, freq, qval, g) end
    end

    methods.ivf_put = ivf_put
    methods.ivf_commit = ivf_commit
    methods.ivf_set_to_target = ivf_set_to_target
    methods.ivf_put_butterworth = ivf_put_butterworth
    methods.ivf_bypass = ivf_bypass
    methods.ivf_band_pass = ivf_band_pass
    methods.ivf_low_cut = ivf_low_cut
    methods.ivf_high_cut = ivf_high_cut
    methods.ivf_low_cut_bw = ivf_low_cut_bw
    methods.ivf_high_cut_bw = ivf_high_cut_bw
    methods.ivf_low_cut_bwq = ivf_low_cut_bwq
    methods.ivf_high_cut_bwq = ivf_high_cut_bwq
    methods.ivf_listen_bell = ivf_listen_bell
    methods.ivf_listen_notch = ivf_listen_notch
    methods.ivf_magnitude = ivf_magnitude
    methods.ivf_analog_magnitude = ivf_analog_magnitude
    -- The include's plain functions
    local ivf = { ivf_bwtoq = ivf_bwtoq, ivf_qtobw = ivf_qtobw }

    return ivf_new, band_set_filter, ivf_set_to_target, ivf_analog_magnitude, ivf
  end)()

  -- The drawing filters (gfx_band1..16), and dyn_curve for a dynamic band's extra lines
  local gfx_band = {}
  for b = 0, NUM_BANDS - 1 do gfx_band[b] = ivf_new() end
  local dyn_curve = ivf_new()
  -- The listen filter: draw_listen_helper() sets it, the listen spectrum is the input through it
  local listen_filter = ivf_new()

  -- from ReEQ2 2.1.0: band_gfx_gain()
  local function band_gfx_gain(b)
    local live = Band_Dyn_On[b] ~= 0 and band_dyn_capable(Band_Type[b]) and Band_Enabled[b] == BAND_STATE_ENABLED
    return Band_Gain[b] + (live and Band_Dyn_Gain[b] or 0)
  end

  -- from ReEQ2 2.1.0: update_visual_filters() (every band, every render)
  local function update_visual_filters()
    local band_scalar = Scale / 100.0
    for b = 0, NUM_BANDS - 1 do
      band_set_filter(gfx_band[b], Band_Type[b], Band_Frequency[b], band_gfx_gain(b) * band_scalar, Band_Q[b], Band_Slope[b])
      ivf_set_to_target(gfx_band[b])
    end
  end

  ------------------------------------------------------------------------------------------------
  -- The layout (the top of ReEQ2's @gfx)
  ------------------------------------------------------------------------------------------------

  -- from ReEQ2 2.1.0: @gfx, the compact flags, margins and panel placement
  local function layout()
    retina = max(S, 1)
    gfx_w, gfx_h = floor(DEFAULT_W * retina + 0.5), floor(DEFAULT_H * retina + 0.5)
    HIDPI = retina >= 1.5
    actual_width = gfx_w / retina
    actual_height = gfx_h / retina
    compact_width = actual_width < 600
    compact_height = actual_height < 320
    very_compact_width = actual_width < 300
    very_compact_height = actual_height < 160
    if very_compact_height then
      HEADER_H = 0
    elseif compact_height then
      HEADER_H = floor(ui_pt(24))
    else
      HEADER_H = floor(ui_pt(34))
    end
    if HEADER_H == 0 then
      TOP_MARGIN = floor(ui_pt(10))
    else
      TOP_MARGIN = HEADER_H + floor((compact_width or compact_height) and ui_pt(10) or ui_pt(16))
    end
    BOTTOM_MARGIN = 40 * max(retina, 1)
    RAISED_BOTTOM = 176 * max(retina, 1)
    if compact_width or compact_height then BOTTOM_MARGIN = 0 end
    ui_dyn_panel = selected_node >= 0 and Band_Dyn_On[selected_node] ~= 0 and band_dyn_capable(Band_Type[selected_node])
    panel_w = floor(ui_dyn_panel and max(ui_pt(560), min(ui_pt(700), gfx_w - ui_pt(8))) or ui_pt(560))
    panel_h = floor(ui_pt(146))
    panel_x = floor(gfx_w / 2 - panel_w / 2)
    panel_y = floor(gfx_h - BOTTOM_MARGIN - ui_pt(44) - panel_h)
    ShowPanel = (PanelEnabled ~= 0 and not compact_width and not compact_height) and 1 or 0
    ENABLE_RAISED_BOTTOM = ShowPanel
    LEFT_MARGIN = 0
    RIGHT_MARGIN = 0
  end

  -- from ReEQ2 2.1.0: freq_to_scx()
  local function freq_to_scx(freq)
    return LEFT_MARGIN + ((gfx_w - LEFT_MARGIN - RIGHT_MARGIN) * log(freq / MIN_FREQ) / FREQ_LOG_MAX)
  end

  -- from ReEQ2 2.1.0: scx_to_freq()
  local function scx_to_freq(x)
    x = MIN_FREQ * exp(FREQ_LOG_MAX * (x - LEFT_MARGIN) / (gfx_w - LEFT_MARGIN - RIGHT_MARGIN))
    return max(min(x, MAX_FREQ), MIN_FREQ)
  end

  -- from ReEQ2 2.1.0: db_to_y()
  local function db_to_y(db)
    local m = 1.0 - (((db / DB_EQ_RANGE) / 2) + 0.5)
    return TOP_MARGIN + (m * (gfx_h - (ui_th1 * 2) - BOTTOM_MARGIN - (RAISED_BOTTOM * ENABLE_RAISED_BOTTOM)))
  end

  -- from ReEQ2 2.1.0: get_filter_x()
  local function get_filter_x(band)
    return freq_to_scx(Band_Frequency[band])
  end

  -- from ReEQ2 2.3.0: cut_q_max(), a Butterworth cut's highest Q at slope step k
  local function cut_q_max(k)
    local n = k + 1
    local m, odd = math.floor(n / 2), n % 2
    if m < 1 then return math.sqrt(0.5) end
    return math.min(40, 60 * math.cos(math.pi * (2 * (m - 1 + odd) + 1 - odd) / (2 * n)) / math.sqrt(2))
  end

  -- from ReEQ2 2.3.0: get_filter_y()
  local function get_filter_y(band)
    local y
    local t = Band_Type[band]
    if t == FILTER_LOW_CUT_BUTTERWORTH or t == FILTER_HIGH_CUT_BUTTERWORTH then
      -- A Butterworth cut's node is 3 dB above its curve at its frequency, so at Q 0.7071 (and at 6 dB/oct)
      -- it sits on the 0 dB line: 20 log10(Q sqrt 2) dB
      if Band_Slope[band] == 0 then
        y = db_to_y(0)
      else
        y = db_to_y(20 * math.log(math.min(Band_Q[band], cut_q_max(Band_Slope[band])) * math.sqrt(2), 10))
      end
    elseif t == FILTER_HIGH_CUT or t == FILTER_LOW_CUT then
      if Band_Slope[band] == 0 then
        y = db_to_y(0)
      else
        -- Convert Q to dB, then to screen Y
        local s = floor(((Band_Slope[band] + 1) * 6) / 12)
        y = db_to_y(((6 * s * log(Band_Q[band])) / log(2)) + (3 * s))
      end
    elseif t == 7 or t == 8 or t == 11 then
      -- Notch, bandpass and allpass don't have gain
      y = db_to_y(0)
    else
      y = db_to_y(Band_Gain[band])
    end
    return max(y, TOP_MARGIN)
  end

  ------------------------------------------------------------------------------------------------
  -- The analyser
  ------------------------------------------------------------------------------------------------

  local spectrum, spectrum_colours = (function()
    -- from spectrum.jsfx-inc: the state spectrum.init() and ReEQ2's update_state() set (0 dB ceiling,
    -- -90 dB floor, 4.5 dB/oct tilt), the colours and fills per buffer, and the geometry. tok[k] is the
    -- token buffer k draws in, for picking. ghost_w and ghost_style are set by draw_dyn_ghost().
    local spectrum = {
      ceiling = 0, noise_floor = -90, tilt = 4.5, min_freq = 10, max_freq = 30000,
      top_margin = 10, bottom_margin = 0, left_margin = 0, right_margin = 0,
      red = {}, green = {}, blue = {}, alpha = {}, fill = {}, tok = {},
      heat_r0 = 0, heat_g0 = 0, heat_b0 = 0, ghost_w = {}, ghost_style = 0,
    }
    spectrum.freq_log_max = log(spectrum.max_freq / spectrum.min_freq)

    -- from ReEQ2 2.1.0: update_state(), the smoothing: Smoothing_Value 1 (its default) is 1/48 octave
    local Smoothing_Value = 1
    spectrum.smooth = Smoothing_Value == 1 and 1 / 48 or Smoothing_Value == 2 and 1 / 24 or Smoothing_Value == 3 and 1 / 12
      or Smoothing_Value == 4 and 1 / 6 or 0

    -- from spectrum.jsfx-inc: spectrum.set_color(), spectrum.set_fill()
    function spectrum.set_color(k, r, g, b, a)
      spectrum.red[k] = r; spectrum.green[k] = g; spectrum.blue[k] = b; spectrum.alpha[k] = a
    end

    function spectrum.set_fill(k, fill)
      spectrum.fill[k] = fill
    end

    -- from spectrum.jsfx-inc: spectrum.freq_to_x(), spectrum.x_to_freq()
    function spectrum.freq_to_x(freq)
      return spectrum.left_margin + ((gfx_w - spectrum.left_margin - spectrum.right_margin) * log(freq / spectrum.min_freq) / spectrum.freq_log_max)
    end

    function spectrum.x_to_freq(x)
      x = spectrum.min_freq * exp(spectrum.freq_log_max * (x - spectrum.left_margin) / (gfx_w - spectrum.left_margin - spectrum.right_margin))
      return max(min(x, spectrum.max_freq), spectrum.min_freq)
    end

    -- from spectrum.jsfx-inc: spectrum.01_to_y()
    function spectrum.zo_to_y(zo)
      return spectrum.top_margin + (1.0 - zo) * (gfx_h - spectrum.top_margin - spectrum.bottom_margin - gfx.texth)
    end

    -- from spectrum.jsfx-inc: spectrum.magnitude_to_01(), from a level in dB rather than a power
    function spectrum.db_to_01(db, freq)
      if spectrum.tilt ~= 0.0 then db = db + spectrum.tilt * ((log(freq) / log(2)) - (log(1024) / log(2))) end
      return 1.0 - ((db - spectrum.ceiling) / (spectrum.noise_floor - spectrum.ceiling))
    end

    -- from spectrum.jsfx-inc: spectrum.draw_line()
    function spectrum.draw_line(x1, y1, x2, y2)
      x1 = floor(x1)
      x2 = floor(x2)
      y2 = floor(y2)
      gfx.line(x1, y1 - 1, x2, y2 - 1, 1)
      gfx.line(x1, y1, x2 - 1, y2 - 1, 1)
    end

    -- from ReEQ2 2.1.0: an_set_color()
    local function an_set_color(k, t, f)
      local p = Pal[t]
      spectrum.set_color(k, p[1] / 255 * f, p[2] / 255 * f, p[3] / 255 * f, p[4])
      spectrum.tok[k] = t
    end

    -- The listen buffers' colours (spectrum_colours() sets them directly), for picking as T_AN_LISTEN
    local function an_set_listen(k, r, g, b, a)
      spectrum.set_color(k, r, g, b, a)
      spectrum.tok[k] = T.AN_LISTEN
    end

    -- from ReEQ2 2.1.0: spectrum_colours()
    local function spectrum_colours()
      local fade = do_listen ~= 0 and 0.5 or 1.0

      -- Listen spectrum colours
      local p = Pal[T.AN_LISTEN]
      local listline_r = (p[1] / 255) * 0.80
      local listline_g = (p[2] / 255) * 0.80
      local listline_b = (p[3] / 255) * 0.80

      local dm = Display_Mode
      if dm == 0 then
        spectrum.set_fill(0, 1)
        an_set_color(0, T.AN_FILL, fade)
        spectrum.set_fill(2, 0)
        an_set_color(2, T.AN_PRE_EQ, 1)
        spectrum.set_fill(1, 1)
        an_set_color(1, T.AN_FILL_2, fade)
        spectrum.set_fill(3, 0)
        an_set_color(3, T.AN_PRE_EQ_2, 1)
        spectrum.set_fill(4, 0)
        an_set_listen(4, listline_r, listline_g, listline_b, p[4])
        spectrum.set_fill(5, 0)
        an_set_listen(5, listline_r * 0.80, listline_g * 0.80, listline_b * 0.80, p[4])
      elseif dm == 3 then
        local p = Pal[T.AN_HEAT_LOW]
        spectrum.heat_r0 = p[1] / 255 * fade
        spectrum.heat_g0 = p[2] / 255 * fade
        spectrum.heat_b0 = p[3] / 255 * fade
        spectrum.set_fill(0, 2)
        an_set_color(0, T.AN_HEAT_HIGH, fade)
        spectrum.set_fill(1, 1)
        an_set_color(1, T.AN_HEAT_2, fade)
        spectrum.set_fill(2, 0)
        an_set_color(2, T.AN_PRE_EQ, 1)
        spectrum.set_fill(3, 0)
        an_set_color(3, T.AN_PRE_EQ_2, 1)
        spectrum.set_fill(4, 0)
        an_set_listen(4, listline_r, listline_g, listline_b, p[4])
        spectrum.set_fill(5, 0)
        an_set_listen(5, listline_r * 0.80, listline_g * 0.80, listline_b * 0.80, p[4])
      elseif dm == 1 then
        spectrum.set_fill(0, 0)
        an_set_color(0, T.AN_LINE, fade)
        spectrum.set_fill(2, 0)
        an_set_color(2, T.AN_PRE_EQ, 1)
        spectrum.set_fill(1, 0)
        an_set_color(1, T.AN_LINE_2, fade)
        spectrum.set_fill(3, 0)
        an_set_color(3, T.AN_PRE_EQ_2, 1)
        spectrum.set_fill(4, 0)
        an_set_listen(4, listline_r, listline_g, listline_b, p[4])
        spectrum.set_fill(5, 0)
        an_set_listen(5, listline_r * 0.80, listline_g * 0.80, listline_b * 0.80, p[4])
      end

      -- A dynamic band's ghost spectrum, in every mode (spectrum.init() gives buffer 6 fill 3)
      spectrum.set_fill(6, 3)
      an_set_color(6, T.AN_GHOST, 1)
    end

    -- In place of the FFT, a canned drum loop: pre-EQ levels in dB (as its bins would read, before the
    -- display's tilt) for Mid and for Side, a fixed ripple over the mids and highs, and post-EQ the same
    -- through the bands. The analyser runs at srate (48 kHz) in 8192-point blocks (Block_Value 2), so it
    -- ends at Nyquist, short of the graph's right edge.
    local AN_FFT = 8192
    local AN_MID = {
      { 10, -72 }, { 15, -52 }, { 20, -36 }, { 30, -22 }, { 40, -13 }, { 55, -7 }, { 70, -8 }, { 90, -13 },
      { 120, -18 }, { 160, -19 }, { 200, -17 }, { 260, -21 }, { 350, -26 }, { 500, -30 }, { 700, -33 },
      { 1000, -36 }, { 1500, -39 }, { 2200, -40 }, { 3000, -42 }, { 4500, -46 }, { 6500, -49 }, { 9000, -50 },
      { 12000, -55 }, { 15000, -62 }, { 18000, -71 }, { 21000, -82 }, { 24000, -96 },
    }
    local AN_SIDE = {
      { 10, -88 }, { 20, -64 }, { 40, -56 }, { 60, -49 }, { 100, -43 }, { 160, -38 }, { 250, -36 },
      { 400, -37 }, { 800, -40 }, { 1500, -43 }, { 3000, -46 }, { 6000, -50 }, { 10000, -53 }, { 14000, -59 },
      { 18000, -69 }, { 21000, -80 }, { 24000, -96 },
    }

    -- The canned level at f: a Catmull-Rom curve through the points, over log frequency
    local function an_points_db(pts, f)
      local n = #pts
      if f <= pts[1][1] then return pts[1][2] end
      if f >= pts[n][1] then return pts[n][2] end
      local i = 2
      while pts[i][1] < f do i = i + 1 end
      local p0, p1, p2, p3 = pts[max(i - 2, 1)][2], pts[i - 1][2], pts[i][2], pts[min(i + 1, n)][2]
      local t = log(f / pts[i - 1][1]) / log(pts[i][1] / pts[i - 1][1])
      local t2 = t * t
      return 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t2 * t)
    end

    -- A fixed ripple: smooth value noise over log frequency from a table filled once by a fixed
    -- generator (Park-Miller), fading in above about 60 Hz, where the bins get close together
    local AN_NOISE = {}
    local seed = 20261031
    for i = 0, 255 do
      seed = (seed * 16807) % 2147483647
      AN_NOISE[i] = seed / 2147483647 * 2 - 1
    end

    local function an_noise(x)
      local i = floor(x)
      local t = x - i
      t = t * t * (3 - 2 * t)
      local a, b = AN_NOISE[i % 256], AN_NOISE[(i + 1) % 256]
      return a + (b - a) * t
    end

    local function an_ripple(f, part)
      local l = log(f) / log(2)
      local k = min(max((l - 6) / 4, 0), 1)
      return k * (2.0 * an_noise(l * 40 + part * 101) + 1.0 * an_noise(l * 110 + part * 53))
    end

    -- The bands' response in dB at f on part 1 (Mid) or 2 (Side): Stereo bands and that part's own, as
    -- the audio gets it (the digital response)
    local function an_eq_db(f, part)
      local m = 1
      for b = 0, NUM_BANDS - 1 do
        local g = Band_Group[b]
        if Band_Enabled[b] == BAND_STATE_ENABLED and (g == 0 or g == part) then
          m = m * gfx_band[b]:ivf_magnitude(f)
        end
      end
      return 20 * log10(max(m, 0.000001))
    end

    -- The listen signal on part 1 (Mid) or 2 (Side): the input through the listen filter in the listen
    -- band's placement (the @sample listen path), in dB, or nil where it's silent. A Left or Right band
    -- leaves the other side silent, so Mid and Side each get half.
    local function an_listen_db(f, part)
      local g = listen_group
      if (g == 1 and part == 2) or (g == 2 and part == 1) then return nil end
      local db = 20 * log10(max(listen_filter:ivf_magnitude(f) * listen_gain, 0.000001))
      if g == 3 or g == 4 then db = db - 6.02 end
      return db
    end

    -- from spectrum.jsfx-inc: spectrum.box_pass()
    function spectrum.box_pass(buf, tmp, n, r)
      local sum = 0
      for i = 0, min(r, n) - 1 do sum = sum + buf[i] end
      for i = 0, n - 1 do
        local hi, lo = i + r, i - r - 1
        if hi < n then sum = sum + buf[hi] end
        if lo >= 0 then sum = sum - buf[lo] end
        local w = min(hi, n - 1) - max(lo + 1, 0) + 1
        tmp[i] = sum / w
      end
      for i = 0, n - 1 do buf[i] = tmp[i] end
    end

    -- Buffer k's level per pixel column (0..1, tilt applied, at rest), as spectrum.draw() works it out
    -- from the FFT: 0 Mid and 1 Side (before the EQ while a band is heard on its own: the bands are
    -- skipped then), 2 and 3 the same before the EQ, 4 and 5 the listen signal, 6 the ghost's band's
    -- detector input (its own input in its placement: Side for a Side band, else Mid, which stands in
    -- for Left and Right too). Smoothed as spectrum.draw() smooths. Also the last column (Nyquist's)
    -- and the column count.
    function spectrum.levels(k)
      local ncol = min(floor(gfx_w), 16384)
      local listening = do_listen ~= 0 or listen_node ~= -1
      local part
      if k == 6 then
        part = Band_Group[max(Ghost_Band, 0)] == 2 and 2 or 1
      else
        part = (k == 0 or k == 2 or k == 4) and 1 or 2
      end
      local pts = part == 1 and AN_MID or AN_SIDE
      local lev = {}
      for c = 0, ncol - 1 do
        local f = spectrum.x_to_freq(c + 0.5)
        local db = an_points_db(pts, f) + an_ripple(f, part)
        if k < 2 and not listening then db = db + an_eq_db(f, part) end
        if k == 4 or k == 5 then
          local ldb = an_listen_db(f, part)
          db = ldb and db + ldb or -400
        end
        lev[c] = max(spectrum.db_to_01(db, f), 0)
      end

      -- Optional smoothing, in octaves: three box passes approximate a Gaussian
      if spectrum.smooth > 0 then
        local sg = spectrum.smooth * (gfx_w - spectrum.left_margin - spectrum.right_margin) * log(2) / spectrum.freq_log_max
        local r = floor((sqrt(4 * sg * sg + 1) - 1) * 0.5)
        if r >= 1 then
          local tmp = {}
          for _ = 1, 3 do spectrum.box_pass(lev, tmp, ncol, r) end
        end
      end

      local nb = AN_FFT * 0.5
      local last = min(floor(spectrum.freq_to_x((nb - 1) * srate / AN_FFT)), ncol - 1)
      return lev, last, ncol
    end

    -- from spectrum.jsfx-inc: spectrum.draw(), from the canned levels (no peaks: Show_Peaks is off)
    function spectrum.draw(bufindex)
      local yb, last, ncol = spectrum.levels(bufindex)
      local spectrum_fill = spectrum.fill[bufindex]
      local r, g, b, a = spectrum.red[bufindex], spectrum.green[bufindex], spectrum.blue[bufindex], spectrum.alpha[bufindex]
      local tok = spectrum.tok[bufindex]
      local bottom = gfx_h - spectrum.bottom_margin - gfx.texth
      local top = spectrum.top_margin

      if spectrum_fill == 2 then
        -- Heat: a fill under the line, each column coloured by its level (picks as quiet below halfway)
        for c = 0, last do
          local y = floor(min(spectrum.zo_to_y(yb[c]), bottom))
          local span = min(max((spectrum.noise_floor + yb[c] * (spectrum.ceiling - spectrum.noise_floor) + 54) / 42, 0), 1)
          span = span * span * (3 - 2 * span)
          if y < bottom and span > 0.004 then
            local ty = min(1, a * (0.25 + 0.75 * span) * (0.85 + 0.45 * span * span))
            gradrect(span < 0.5 and T.AN_HEAT_LOW or tok, c, y, 1, bottom - y,
              spectrum.heat_r0 + (r - spectrum.heat_r0) * span,
              spectrum.heat_g0 + (g - spectrum.heat_g0) * span,
              spectrum.heat_b0 + (b - spectrum.heat_b0) * span,
              ty, 0, 0, 0, 0, 0, 0, 0, -0.9 * ty / max(bottom - y, 1))
          end
        end
      elseif spectrum_fill == 1 then
        -- Fill: a vertical fade per column, anchored to the graph
        local span = max(bottom - top, 1)
        for c = 0, last do
          local y = floor(min(spectrum.zo_to_y(yb[c]), bottom))
          if y < bottom then
            gradrect(tok, c, y, 1, bottom - y, r, g, b, a * (0.07 + 0.93 * (bottom - y) / span), 0, 0, 0, 0, 0, 0, 0, -0.93 * a / span)
          end
        end
      end

      -- Ghost (fill 3): each column's fill and line as opaque as ghost_w says, and no peaks. The fill is
      -- in the style of the main display (ghost_style: 0 Fill, 1 Line, 2 Heat), in the ghost's own
      -- colour, and shows only where ghost_w is above 0.25.
      if spectrum_fill == 3 then
        local span = max(bottom - top, 1)
        if spectrum.ghost_style ~= 1 then
          for c = 0, last do
            local v = (spectrum.ghost_w[c] - 0.25) / 0.75
            local y = floor(min(spectrum.zo_to_y(yb[c]), bottom))
            if v > 0.01 and y < bottom then
              if spectrum.ghost_style == 2 then
                -- As Heat: strength from the level over its working range, fading towards the floor
                local sg = min(max((spectrum.noise_floor + yb[c] * (spectrum.ceiling - spectrum.noise_floor) + 54) / 42, 0), 1)
                sg = sg * sg * (3 - 2 * sg)
                local ty = min(1, a * (0.25 + 0.75 * sg) * (0.85 + 0.45 * sg * sg)) * 0.6 * v
                gradrect(tok, c, y, 1, bottom - y, r, g, b, ty, 0, 0, 0, 0, 0, 0, 0, -0.9 * ty / max(bottom - y, 1))
              else
                -- As Fill: a vertical fade anchored to the graph, so louder reads brighter
                local ty = a * 0.5 * v
                gradrect(tok, c, y, 1, bottom - y, r, g, b, ty * (0.07 + 0.93 * (bottom - y) / span), 0, 0, 0, 0, 0, 0, 0, -0.93 * ty / span)
              end
            end
          end
        end
        if picking then pick_set(tok) else gfx.r = r; gfx.g = g; gfx.b = b end
        local ly = min(spectrum.zo_to_y(yb[0]), bottom)
        for c = 1, last do
          local ty = min(spectrum.zo_to_y(yb[c]), bottom)
          local la = a * spectrum.ghost_w[c]
          gfx.a = A(la)
          if la > 0.01 and (ly < bottom - 1 or ty < bottom - 1) then spectrum.draw_line(c - 1, ly, c, ty) end
          ly = ty
        end
        return
      end

      -- Line: a faint tint over a heat map, a pale tint of the fill colour over a fill, or the colour
      if picking then
        pick_set(tok)
      elseif spectrum_fill == 2 then
        gfx.r = r + (1 - r) * 0.35; gfx.g = g + (1 - g) * 0.35; gfx.b = b + (1 - b) * 0.35; gfx.a = 0.5
      elseif spectrum_fill ~= 0 then
        gfx.r = r + (1 - r) * 0.45; gfx.g = g + (1 - g) * 0.45; gfx.b = b + (1 - b) * 0.45; gfx.a = 0.7
      else
        gfx.r = r; gfx.g = g; gfx.b = b; gfx.a = a
      end
      local ly = min(spectrum.zo_to_y(yb[0]), bottom)
      for c = 1, last do
        local ty = min(spectrum.zo_to_y(yb[c]), bottom)
        if ly < bottom - 1 or ty < bottom - 1 then spectrum.draw_line(c - 1, ly, c, ty) end
        ly = ty
      end
      -- Ending at Nyquist, inside the graph: drop to the floor rather than stop in mid air
      if last < ncol - 1 and ly < bottom - 1 then spectrum.draw_line(last, ly, last, bottom) end
    end

    return spectrum, spectrum_colours
  end)()

  ------------------------------------------------------------------------------------------------
  -- The graph: grid, band areas and curves, nodes
  ------------------------------------------------------------------------------------------------

  local draw_grid, draw_filter_bands, draw_filter_response, draw_dyn_static, draw_dyn_range, draw_nodes = (function()
    -- from ReEQ2 2.2.0: draw_grid()
    local function draw_grid()
      local gb = gfx_h - BOTTOM_MARGIN - ui_pt(20)

      -- Frequency lines, brighter at each decade, and labels (Body, for legibility at 1x)
      gfx.setfont(FONT_BODY)
      local f = 10
      repeat
        local x = floor(freq_to_scx(f)) + 0.5
        local major = f == 100 or f == 1000 or f == 10000
        ui_cola(major and T.GRID_DECADE or T.GRID, 1)
        gfx.line(x, HEADER_H, x, gb, 0)
        if (f == 20 or f == 50 or f == 100 or f == 200 or f == 500 or f == 1000 or f == 2000 or f == 5000 or f == 10000 or f == 20000)
          and (not compact_width or major) then
          local lab = f >= 1000 and string.format("%dk", floor(f / 1000)) or string.format("%d", f)
          local lw = ui_text_w(lab)
          ui_cola(T.AXIS_LABEL, 1)
          -- Kept inside the window: 20k sits close to the right edge
          ui_text_l(min(x - lw * 0.5, gfx_w - lw - ui_pt(4)), gb + ui_pt(2), ui_pt(14), lab)
        end
        f = f + (f < 100 and 10 or f < 1000 and 100 or f < 10000 and 1000 or 10000)
      until not (f < MAX_FREQ)

      -- Gain lines and labels on the right
      local db, k = DB_EQ_RANGE, 0
      repeat
        local y = floor(db_to_y(db)) + 0.5
        ui_cola(db == 0 and T.ZERO_LINE or T.GRID, 1)
        gfx.line(0, y, gfx_w, y, 0)
        if not compact_height or k % 2 == 0 then
          local lab = db > 0 and string.format("+%d", db) or db < 0 and string.format("−%d", -db) or "0"
          -- The top label doubles as the dB range button (ui_draw_header draws it, over the curves)
          if k == 0 and not compact_width and not compact_height then
            ui_dbb_lab = lab; ui_dbb_cy = y
          else
            ui_cola(T.DB_LABEL, 1)
            ui_text_r(gfx_w - ui_pt(42), y - ui_pt(8), ui_pt(32), ui_pt(16), lab)
          end
        end
        db = db - DB_EQ_RANGE_STEPS
        k = k + 1
      until not (db >= -DB_EQ_RANGE)

      gfx.setfont(FONT_BASE)
    end

    -- from ReEQ2 2.1.0: draw_line()
    local function draw_line(x1, y1, x2, y2)
      x1 = floor(x1)
      x2 = floor(x2)
      y2 = floor(y2)
      gfx.a = 1
      gfx.line(x1, y1, x2, y2, 1)
    end

    -- from ReEQ2 2.1.0: draw_thick_line()
    local function draw_thick_line(x1, y1, x2, y2)
      x1 = floor(x1)
      x2 = floor(x2)
      y2 = floor(y2)
      gfx.a = 1
      gfx.line(x1, y1, x2, y2, 1)
      gfx.a = A(0.25)
      gfx.line(x1 - 1, y1 - 1, x2 + 1, y2 - 1, 1)
      gfx.line(x1 - 1, y1 + 1, x2 + 1, y2 + 1, 1)
    end

    -- from ReEQ2 2.2.0: draw_filter_bands() (the areas pick as T_BAND_AREA, the curves as the band)
    local function draw_filter_bands()
      -- Band fill opacity at the curve and at the 0dB line
      local FILL_ALPHA_CURVE = Pal[T.BAND_AREA][4]
      local FILL_ALPHA_LINE = FILL_ALPHA_CURVE * 0.1
      local step = gfx_w / 1000
      local bottom = gfx_h - BOTTOM_MARGIN - gfx.texth
      local midp = db_to_y(0)

      for band = 0, NUM_BANDS - 1 do
        local state = Band_Enabled[band]
        if state ~= BAND_STATE_OFF then
          gfx.r, gfx.g, gfx.b = Band_Red[band], Band_Green[band], Band_Blue[band]
          local xo1 = 0
          local yo1 = (gfx_h - gfx.texth) * 0.5
          for point = 0, 1000 do
            local xf = point == 1000 and gfx_w or point * step
            local freq = scx_to_freq(xf)
            local transfer = ivf_analog_magnitude(gfx_band[band], freq)
            if transfer < 0.001 then transfer = 0.001 end
            local m = 20 * log10(transfer)
            local scy = db_to_y(m)

            if point > 0 then
              local x0, y0, x1, y1 = xo1, yo1, xf, scy
              if yo1 < bottom and scy < bottom then
                gfx.a = 1.0
                -- Clip line against bottom
                if y1 > bottom then
                  local delta = (bottom - y0) / (y1 - y0)
                  x1 = x0 + delta * (x1 - x0)
                  y1 = bottom
                end
                if y0 > bottom then
                  local delta = (bottom - y1) / (y0 - y1)
                  x0 = x1 + delta * (x0 - x1)
                  y0 = bottom
                end
                if very_compact_width or very_compact_height then draw_line(x0, y0, x1, y1) else draw_thick_line(x0, y0, x1, y1) end
              end

              -- Fill in, one column per step, fading from the curve towards the 0dB line
              local tx0, lx0 = floor(xf), floor(xo1)
              y1 = min(scy, bottom)
              y0 = min(yo1, bottom)
              if state == BAND_STATE_ENABLED and tx0 > lx0 then
                local yc = (y0 + y1) * 0.5 + (HIDPI and 2 or 1)
                local fh = midp - yc
                if fh >= 1 then
                  -- Boost, the curve is above the line
                  gradrect(T.BAND_AREA, lx0, yc, tx0 - lx0, fh, Band_Red[band], Band_Green[band], Band_Blue[band], FILL_ALPHA_CURVE,
                    0, 0, 0, 0, 0, 0, 0, (FILL_ALPHA_LINE - FILL_ALPHA_CURVE) / fh)
                elseif fh <= -1 then
                  -- Cut, the curve is below the line
                  gradrect(T.BAND_AREA, lx0, midp, tx0 - lx0, -fh, Band_Red[band], Band_Green[band], Band_Blue[band], FILL_ALPHA_LINE,
                    0, 0, 0, 0, 0, 0, 0, (FILL_ALPHA_CURVE - FILL_ALPHA_LINE) / -fh)
                end
              end
            end

            xo1 = xf; yo1 = scy
          end
        end
      end
    end

    -- from ReEQ2 2.1.0: draw_filter_response()
    local function draw_filter_response(group, tc)
      local step = 1
      ui_cola(tc, 1)
      local be = {}
      for b = 0, NUM_BANDS - 1 do be[b] = Band_Enabled[b] == BAND_STATE_ENABLED and Band_Group[b] == group end
      local bottom = gfx_h - BOTTOM_MARGIN - gfx.texth

      local xo1 = 0
      local yo1 = (gfx_h - gfx.texth) * 0.5
      local xf = 0
      repeat
        local freq = scx_to_freq(xf)
        local m = 1.0
        for b = 0, NUM_BANDS - 1 do
          if be[b] then m = m * ivf_analog_magnitude(gfx_band[b], freq) end
        end
        if m < 0.001 then m = 0.001 end
        m = 20 * log10(m)
        local scy = db_to_y(m)

        if xo1 > 0 and not (yo1 > bottom and scy > bottom) then
          local x0, y0, x1, y1 = xo1, yo1, xf, scy
          -- Clip line against bottom
          if y1 > bottom then
            local delta = (bottom - y0) / (y1 - y0)
            x1 = x0 + delta * (x1 - x0)
            y1 = bottom
          end
          if y0 > bottom then
            local delta = (bottom - y1) / (y0 - y1)
            x0 = x1 + delta * (x0 - x1)
            y0 = bottom
          end

          gfx.a = 1
          if HIDPI then
            draw_thick_line(x0, y0, x1, y1)
            -- If we're not in very compact mode then thicken the line up more
            if not very_compact_width and not very_compact_height then
              if abs(x1 - x0) > abs(y1 - y0) then
                draw_thick_line(x0, y0 + 1, x1, y1 + 1)
                draw_thick_line(x0, y0 - 1, x1, y1 - 1)
              else
                draw_thick_line(x0 + 1, y0, x1 + 1, y1)
                draw_thick_line(x0 - 1, y0, x1 - 1, y1)
              end
            end
          else
            if very_compact_width or very_compact_height then draw_line(x0, y0, x1, y1) else draw_thick_line(x0, y0, x1, y1) end
          end
        end

        xo1 = xf; yo1 = scy
        xf = xf + step
      until not (xf < gfx_w)
    end

    -- from ReEQ2 2.1.0: draw_dyn_curve()
    local function draw_dyn_curve(t, f, g, qv, dash, gap)
      local s = ui_pt(1)
      band_set_filter(dyn_curve, t, f, g, qv, 0)
      ivf_set_to_target(dyn_curve)
      local bottom = gfx_h - BOTTOM_MARGIN - gfx.texth
      local step = max(2, floor(2 * s))
      local period = (dash + gap) * s
      local xf, xo, yo = 0, 0, 0
      for _ = 1, ceil(gfx_w / step) + 1 do
        local freq = scx_to_freq(xf)
        local m = max(ivf_analog_magnitude(dyn_curve, freq), 0.001)
        local scy = db_to_y(20 * log10(m))
        if xf > 0 and yo < bottom and scy < bottom and xf - floor(xf / period) * period < dash * s then gfx.line(xo, yo, xf, scy, 1) end
        xo = xf; yo = scy
        xf = xf + step
      end
    end

    -- from ReEQ2 2.1.0: draw_dyn_static()
    local function draw_dyn_static()
      for b = 0, NUM_BANDS - 1 do
        local t = Band_Type[b]
        if Band_Dyn_On[b] ~= 0 and band_dyn_capable(t) and Band_Enabled[b] == BAND_STATE_ENABLED and abs(Band_Dyn_Gain[b]) > 0.1 then
          gfx.r, gfx.g, gfx.b = Band_Red[b], Band_Green[b], Band_Blue[b]; gfx.a = A(0.55)
          draw_dyn_curve(t, Band_Frequency[b], Band_Gain[b] * Scale / 100, Band_Q[b], 1.5, 2.5)
        end
      end
    end

    -- from ReEQ2 2.1.0: draw_dyn_range() (nothing hovered or dragged)
    local function draw_dyn_range()
      local s = ui_pt(1)
      local b = selected_node
      if b >= 0 then
        local t = Band_Type[b]
        if Band_Dyn_On[b] ~= 0 and band_dyn_capable(t) and Band_Enabled[b] == BAND_STATE_ENABLED then
          gfx.r, gfx.g, gfx.b = Band_Red[b], Band_Green[b], Band_Blue[b]; gfx.a = A(0.7)
          draw_dyn_curve(t, Band_Frequency[b], (Band_Gain[b] + Band_Dynamic_Range[b]) * Scale / 100, Band_Q[b], 6, 4)

          local bottom = gfx_h - BOTTOM_MARGIN - gfx.texth
          local x, y = floor(get_filter_x(b)) + 0.5, get_filter_y(b)
          local hy = min(max(db_to_y(Band_Gain[b] + Band_Dynamic_Range[b]), TOP_MARGIN), bottom - 6 * s)
          local nr = ui_pt(8)
          if abs(hy - y) > nr + 3 * s then
            -- Stem from the node's edge to the handle
            gfx.a = A(0.5)
            if hy > y then gfx.line(x, y + nr, x, hy - 4.5 * s, 0) else gfx.line(x, hy + 4.5 * s, x, y - nr, 0) end

            -- The live gain
            local ly = db_to_y(Band_Gain[b] + Band_Dyn_Gain[b])
            if abs(Band_Dyn_Gain[b]) > 0.05 and ly < bottom then
              ui_cola(T.HIGHLIGHT, 0.9)
              gfx.rect(floor(x - 5 * s), floor(ly - 0.75 * s), floor(10 * s), max(1, floor(1.5 * s)), 1)
            end

            -- The handle: a ring in the band colour
            local hov = false
            ui_col(T.TILE)
            gfx.circle(x, hy, (hov and 5.5 or 4.5) * s, 1, 1)
            gfx.r, gfx.g, gfx.b = Band_Red[b], Band_Green[b], Band_Blue[b]
            ui_thick_arc(x, hy, (hov and 5.5 or 4.5) * s, 0, 2 * PI, 1.5 * s)
          end
        end
      end
    end

    -- from ReEQ2 2.1.0: draw_node_stereo()
    local function draw_node_stereo(band, x, y, alpha)
      local size = ui_pt(7.5)
      ui_cola(T.HIGHLIGHT, alpha)
      local function arcs(a0, a1)
        local start, stop = a0 * (2 * PI / 16), a1 * (2 * PI / 16)
        gfx.arc(x, y, size * 2, start, stop, 1)
        gfx.arc(x, y, (size * 2) - 0.5, start, stop, 1)
        if HIDPI then gfx.arc(x, y, (size * 2) - 1.0, start, stop, 1) end
      end
      local g = Band_Group[band]
      -- Top + bottom
      if g == 1 then arcs(14, 18); arcs(22, 26) end
      -- Left
      if g == 2 or g == 3 then arcs(26, 30) end
      -- Right
      if g == 2 or g == 4 then arcs(18, 22) end
    end

    -- from ReEQ2 2.1.0: draw_node()
    local function draw_node(band, freq, db, enabled, selected)
      local x = get_filter_x(band)
      local y = get_filter_y(band)
      local size = rscale(9, 18)

      local node_alpha = 1.0
      if y > gfx_h - gfx.texth - BOTTOM_MARGIN - (RAISED_BOTTOM * ENABLE_RAISED_BOTTOM) then node_alpha = 0.5 end
      if y > gfx_h - gfx.texth - BOTTOM_MARGIN then node_alpha = 0 end

      draw_node_stereo(band, x, y, node_alpha)

      -- Halo in the band colour when hovered or selected
      if band == node_hover or selected_node == band then
        gfx.r, gfx.g, gfx.b = Band_Red[band], Band_Green[band], Band_Blue[band]
        gfx.a = A(node_alpha * (selected_node == band and 0.35 or 0.2))
        ui_thick_arc(x, y, ui_pt(12), 0, 2 * PI, ui_pt(2))
      end

      -- Disc in the band colour, a white edge when selected, and a dark band number
      size = selected_node == band and ui_pt(8) or ui_pt(7)
      gfx.r, gfx.g, gfx.b = Band_Red[band], Band_Green[band], Band_Blue[band]
      local da = enabled == 2 and node_alpha or node_alpha * 0.3
      gfx.a = A(da)
      gfx.circle(x, y, size, 1, 1)

      if selected_node == band then
        ui_cola(T.HIGHLIGHT, da)
        ui_thick_arc(x, y, size, 0, 2 * PI, ui_pt(1.5))
      else
        ui_cola(T.NODE_EDGE, da)
        gfx.circle(x, y, size, 0, 1)
      end

      gfx.setfont(FONT_NODE)
      ui_col_a(T.BADGE_TEXT, enabled == 2 and node_alpha or node_alpha * 0.6)
      ui_text_at(x, y, string.format("%d", band + 1))
      gfx.setfont(FONT_BASE)

      -- Draw band selected indicator
      if Band_Selected[band] == 1 then
        ui_cola(T.HIGHLIGHT, band_selected_circle_alpha)
        gfx.circle(x, y, size * 1.5, 0, 1)
        ui_cola(T.HIGHLIGHT, band_selected_circle_alpha * 0.5); gfx.circle(x, y, (size * 1.5) + 1, 0, 1)
        ui_cola(T.HIGHLIGHT, band_selected_circle_alpha * 0.5); gfx.circle(x, y, (size * 1.5) - 1, 0, 1)
      end

      -- Draw connecting line so that we can see which node affects which part of the curve (as in
      -- ReEQ2, the test is of the band's type against BAND_STATE_OFF, so a bell at 100% Scale has none)
      if Band_Type[band] ~= BAND_STATE_OFF or Scale ~= 100 then
        local transfer = ivf_analog_magnitude(gfx_band[band], freq)
        -- Prevent magnitude from blowing up
        if transfer < 0.001 then transfer = 0.001 end
        local m = 20 * log10(transfer)
        local scy = db_to_y(m)

        -- Notch filters transfer is somewhere down the abyss...compensate
        if Band_Enabled[band] == 2 and Band_Type[band] == 7 then scy = gfx_h - BOTTOM_MARGIN - gfx.texth end
        scy = min(gfx_h - BOTTOM_MARGIN - gfx.texth, scy)

        -- From the node's edge to the curve, fading towards the node
        if scy > y then y = min(y + size, scy) else y = max(y - size, scy) end
        local height = abs(scy - y)
        if height >= 1 then
          local width = max(1, floor(ui_pt(1.25) + 0.5))
          local a1 = enabled == 2 and node_alpha or node_alpha * 0.3
          local a0 = a1 * 0.2
          local bt = T.BAND1 + band % 8
          if scy > y then
            gradrect(bt, floor(x - width * 0.5), y, width, height, Band_Red[band], Band_Green[band], Band_Blue[band], a0,
              0, 0, 0, 0, 0, 0, 0, (a1 - a0) / height)
          else
            gradrect(bt, floor(x - width * 0.5), scy, width, height, Band_Red[band], Band_Green[band], Band_Blue[band], a1,
              0, 0, 0, 0, 0, 0, 0, (a0 - a1) / height)
          end
        end
      end
    end

    -- from ReEQ2 2.1.0: draw_nodes()
    local function draw_nodes()
      for band = 0, NUM_BANDS - 1 do
        if Band_Enabled[band] ~= BAND_STATE_OFF then draw_node(band, Band_Frequency[band], Band_Gain[band], Band_Enabled[band], 0) end
      end
    end

    return draw_grid, draw_filter_bands, draw_filter_response, draw_dyn_static, draw_dyn_range, draw_nodes
  end)()

  ------------------------------------------------------------------------------------------------
  -- Listening, dynamics detectors and the ghost spectrum, and the hover card (which shows for the
  -- band being heard)
  ------------------------------------------------------------------------------------------------

  local draw_listen_helper, draw_info_panel, draw_dyn_detectors, draw_dyn_ghost, dyn_ghost_ok, dyn_det_freq, dyn_det_q = (function()
    local ivf_bwtoq, ivf_qtobw = ivf.ivf_bwtoq, ivf.ivf_qtobw
    -- For weighting the ghost spectrum by the band's detector response
    local ghost_det = ivf_new()
    local listen_width, listen_q, listen_freq = 0.10, 0.7071, 1000

    -- from ReEQ2 2.1.0: round(), log2()
    local function round(v)
      local sg = v > 0 and 1 or v < 0 and -1 or 0
      return floor(v + 0.5 * sg)
    end

    local function log2(x)
      return log(x) / log(2)
    end

    -- from ReEQ2 2.1.0: y_to_db()
    local function y_to_db(y)
      local m = (y - TOP_MARGIN) / (gfx_h - (ui_th1 * 2) - BOTTOM_MARGIN - (RAISED_BOTTOM * ENABLE_RAISED_BOTTOM))
      m = (1.0 - (m + 0.5)) * 2 * DB_EQ_RANGE
      return max(min(m, DB_EQ_RANGE), -DB_EQ_RANGE)
    end

    -- from ReEQ2 2.1.0: dyn_det_freq_u(), dyn_det_width(): an unlinked detector's frequency (20Hz to
    -- 20kHz, below Nyquist) and width (0.25 to 8 octaves)
    local function dyn_det_freq_u(b)
      return min(max(Band_Dyn_DetFreq[b], 20), min(20000, 0.45 * srate))
    end

    local function dyn_det_width(b)
      return min(max(Band_Dyn_DetWidth[b], 0.25), 8)
    end

    -- from ReEQ2 2.1.0: dyn_det_put(), into the filter det (EEL's this). Returns the gain that brings the
    -- detector's centre to 0dB (1 when linked).
    local function dyn_det_put(det, b)
      local t = Band_Type[b]
      if Band_Dyn_Link[b] ~= 0 then
        local f = Band_Frequency[b]
        if t == FILTER_LOW_SHELF then
          det:ivf_put(1, 1, f, 0.7071, 1)
        elseif t == FILTER_HIGH_SHELF then
          det:ivf_put(1, 0, f, 0.7071, 1)
        else
          det:ivf_put(1, 5, f, 0.5 / Band_Q[b], 1)
        end
        det:ivf_commit(1, false)
        det:ivf_set_to_target()
        return 1
      end
      local f, w = dyn_det_freq_u(b), dyn_det_width(b)
      local fl, fh = max(f * 2 ^ (-0.5 * w), 10), min(f * 2 ^ (0.5 * w), 0.45 * srate)
      if fh < fl * 1.05 then fl = fh / 1.05 end
      local n = det:ivf_put_butterworth(1, 0, fl, 4)
      n = det:ivf_put_butterworth(n, 1, fh, 4)
      det:ivf_commit(n - 1, false)
      det:ivf_set_to_target()
      -- 0dB where the pair peaks, between its corners (the response the audio actually gets)
      local m = det:ivf_magnitude(sqrt(fl * fh))
      return 1 / max(m, 0.05)
    end

    -- from ReEQ2 2.1.0: dyn_det_freq(), dyn_det_q()
    local function dyn_det_freq(b)
      return Band_Dyn_Link[b] ~= 0 and Band_Frequency[b] or dyn_det_freq_u(b)
    end

    local function dyn_det_q(b)
      return Band_Dyn_Link[b] ~= 0 and Band_Q[b] or 1.41 / dyn_det_width(b)
    end

    -- from ReEQ2 2.1.0: dyn_ghost_ok()
    local function dyn_ghost_ok(b)
      return b >= 0 and Band_Dyn_On[b] ~= 0 and band_dyn_capable(Band_Type[b]) and Band_Enabled[b] == BAND_STATE_ENABLED
        and (Band_Dyn_Source[b] > 0 or Band_Dyn_Link[b] == 0)
    end

    -- from ReEQ2 2.1.0: dyn_det_on(), dyn_det_nx(), dyn_det_ny()
    local function dyn_det_on(b)
      return Band_Dyn_On[b] ~= 0 and band_dyn_capable(Band_Type[b]) and Band_Enabled[b] ~= BAND_STATE_OFF and Band_Dyn_Link[b] == 0
    end

    local function dyn_det_nx(b)
      return floor(freq_to_scx(dyn_det_freq_u(b))) + 0.5
    end

    local function dyn_det_ny()
      return floor(db_to_y(-0.75 * DB_EQ_RANGE)) + 0.5
    end

    -- from ReEQ2 2.1.0: draw_dyn_detectors() (none hovered or dragged)
    local function draw_dyn_detectors()
      local s = ui_pt(1)
      for b = 0, NUM_BANDS - 1 do
        if dyn_det_on(b) then
          local x, y = dyn_det_nx(b), dyn_det_ny()
          local dim = Band_Enabled[b] ~= BAND_STATE_ENABLED

          -- Dashes from the node's edge to the ring's edge
          local nx, ny = get_filter_x(b), get_filter_y(b)
          local dx, dy = x - nx, y - ny
          local l = sqrt(dx * dx + dy * dy)
          if l > 20 * s then
            gfx.r, gfx.g, gfx.b = Band_Red[b], Band_Green[b], Band_Blue[b]; gfx.a = A(dim and 0.15 or 0.35)
            local n = floor((l - 18 * s) / (6 * s))
            for k = 0, n - 1 do
              local t0 = (9 * s + k * 6 * s) / l
              local t1 = min((12 * s + k * 6 * s) / l, 1 - 9 * s / l)
              gfx.line(nx + dx * t0, ny + dy * t0, nx + dx * t1, ny + dy * t1, 1)
            end
          end

          local hov = false
          ui_col(T.TILE)
          gfx.circle(x, y, 7 * s, 1, 1)
          gfx.r, gfx.g, gfx.b = Band_Red[b], Band_Green[b], Band_Blue[b]; gfx.a = A(dim and 0.4 or 1)
          ui_thick_arc(x, y, (hov and 7.5 or 6.5) * s, 0, 2 * PI, 2 * s)
          gfx.circle(x, y, 2.2 * s, 1, 1)
          if Band_Dyn_Source[b] > 0 then
            gfx.setfont(FONT_CAP)
            ui_text_at(x, y + 15 * s, string.format("SC %d", Band_Dyn_Source[b]))
            gfx.setfont(FONT_BASE)
          end
        end
      end
    end

    -- from ReEQ2 2.1.0: draw_dyn_ghost(). The two washes (the analyser dimmed, the detector's range
    -- tinted) stay out of the pick image, so what's under them can be picked.
    local function draw_dyn_ghost(gb, a)
      local s = ui_pt(1)
      local norm = dyn_det_put(ghost_det, gb)
      local n = min(floor(gfx_w), 16384)
      local cl, cr = -1, -1
      for c = 0, n - 1 do
        local m = norm * ghost_det:ivf_analog_magnitude(spectrum.x_to_freq(c))
        if m >= 0.7071 then
          if cl < 0 then cl = c end
          cr = c
        end
      end
      if cl >= 0 then
        -- Opacity per column for the spectrum's ghost mode: 1 inside, down to 0.25 over 10pt past an
        -- edge (the fill follows this part), then from 0.25 to nothing over 60pt
        for c = 0, n - 1 do
          local d = c < cl and cl - c or c > cr and c - cr or 0
          local w
          if d <= 0 then
            w = 1
          elseif d < 10 * s then
            w = 1 - 0.75 * d / (10 * s)
          else
            w = 0.25 * max(0, 1 - (d - 10 * s) / (60 * s))
          end
          spectrum.ghost_w[c] = w
        end
        local top, bottom = TOP_MARGIN, gfx_h - BOTTOM_MARGIN - gfx.texth

        if not picking then
          -- The analyser dims to about 40% (the background colour over it)
          if Display_Mode ~= 2 then
            ui_cola(T.GRAPH_BG, 0.6 * a)
            gfx.rect(0, top, gfx_w, bottom - top, 1)
          end
          gfx.r, gfx.g, gfx.b = Band_Red[gb], Band_Green[gb], Band_Blue[gb]; gfx.a = 0.06 * a
          gfx.rect(cl, top, cr - cl + 1, bottom - top, 1)
        end

        -- In the main display's style: Line, Heat, or Fill (also when the analyser is off)
        spectrum.ghost_style = Display_Mode == 1 and 1 or Display_Mode == 3 and 2 or 0
        spectrum.alpha[6] = a
        spectrum.draw(6)

        -- The edges (a shelf's detector has only one inside the graph)
        local ew = max(1, floor(1.3 * s + 0.5))
        gfx.r, gfx.g, gfx.b = Band_Red[gb], Band_Green[gb], Band_Blue[gb]; gfx.a = A(0.75 * a)
        if cl > 0 then gfx.rect(cl, top, ew, bottom - top, 1) end
        if cr < n - 1 then gfx.rect(cr - ew + 1, top, ew, bottom - top, 1) end
      end
    end

    -- from ReEQ2 2.1.0: draw_info_panel(), with the mouse over nothing (no node near it, so the card
    -- describes the band being heard, if any; the Shift-drag listen's card follows the mouse and isn't
    -- translated)
    local function draw_info_panel()
      local hide = false
      local read_freq, read_amp
      node_hover = -1
      if node_hover == -1 then node_hover = listen_node end
      if node_hover ~= -1 then
        local band = node_hover
        read_freq = Band_Frequency[band]
        read_amp = y_to_db(get_filter_y(band))
        -- Hide info panel if it's too low
        local y = db_to_y(read_amp)
        if y > gfx_h - gfx.texth - BOTTOM_MARGIN - (RAISED_BOTTOM * ENABLE_RAISED_BOTTOM) then hide = true end
      end

      -- Only show info while hovering band point or in listen mode
      if node_hover ~= -1 then
        local x, y = freq_to_scx(read_freq), db_to_y(read_amp)

        -- 440Hz is A4, get C0 as offset from that
        local C0 = 440 * 2 ^ (-4.75)

        -- Get seminotes (note number), octave and note within octave
        local semi = round(12 * log2(read_freq / C0))
        local octave = floor(semi / 12)
        local note = semi - octave * 12

        -- Cents from the nearest note, rounded
        local note_freq = C0 * 2 ^ (semi / 12)
        local cent = floor(1200 * log2(read_freq / note_freq) + 0.5)

        local keys = "CCDDEFFGGAAB"
        local nn = keys:sub(note + 1, note + 1)
        if note == 1 or note == 3 or note == 6 or note == 8 or note == 10 then nn = nn .. "#" end
        nn = nn .. string.format("%d", octave)
        nn = nn .. (cent < 0 and string.format(" −%d¢", -cent) or string.format(" +%d¢", cent))

        -- The band the card describes
        local band = node_hover

        -- Line 1: frequency and note. Line 2: gain, then Q, slope or cut for shapes that use them.
        local line1
        if read_freq < 1000 then
          line1 = string.format(read_freq < 100 and "%.1f Hz" or "%.0f Hz", read_freq)
        else
          line1 = string.format("%.2f kHz", read_freq / 1000)
        end
        local line2 = string.format("%s dB", ui_fmt_db(read_amp))
        if band >= 0 and band < NUM_BANDS then
          local t = Band_Type[band]
          if ui_is_cut(t) then
            line2 = string.format("%d dB/oct", ui_slope_db(ui_slope_index(Band_Slope[band])))
            if Band_Slope[band] > 0 then
              local q = Band_Q[band]
              if t == FILTER_LOW_CUT_BUTTERWORTH or t == FILTER_HIGH_CUT_BUTTERWORTH then q = math.min(q, cut_q_max(Band_Slope[band])) end
              line2 = line2 .. string.format(" · Res %.2f", q)
            end
          elseif t == FILTER_PULTEC_LOW_SHELF then
            line2 = line2 .. string.format(" · Cut %.2f", Band_Q[band] / 40)
          elseif t ~= FILTER_LOW_CUT_ANALOG and t ~= FILTER_HIGH_CUT_ANALOG then
            if t == FILTER_NOTCH or t == FILTER_BAND_PASS or t == FILTER_ALL_PASS then line2 = "" end
            if #line2 > 0 then line2 = line2 .. " · " end
            line2 = line2 .. string.format("Q %.2f", Band_Q[band])
          end
          -- A dynamic band's live change
          if Band_Dyn_On[band] ~= 0 and band_dyn_capable(t) and Band_Enabled[band] == BAND_STATE_ENABLED then
            line2 = line2 .. string.format(" · %s dB dyn", ui_fmt_db(Band_Dyn_Gain[band]))
          end
        end

        -- Measure and place the card next to the point, kept inside the graph
        gfx.setfont(FONT_EMPH)
        local width = ui_text_w(line1)
        gfx.setfont(FONT_BODY)
        width = max(width + ui_text_w(nn) + ui_pt(4), ui_text_w(line2)) + ui_pt(18)
        local rect_height = ui_pt(42)

        local xbase = x + ui_pt(16)
        if xbase + width > gfx_w - ui_pt(48) then xbase = x - ui_pt(16) - width end
        xbase = max(ui_pt(8), xbase)
        local ybase = y - rect_height - ui_pt(12)
        if ybase < HEADER_H + ui_pt(6) then ybase = y + ui_pt(14) end

        ui_box(xbase, ybase, width, rect_height, ui_pt(5), T.POPOVER, 0.95, T.BORDER)

        gfx.setfont(FONT_EMPH)
        ui_col(T.TEXT)
        ui_text_l(xbase + ui_pt(9), ybase + ui_pt(5), ui_pt(16), line1)
        gfx.setfont(FONT_BODY)
        ui_col(T.TEXT_DIM)
        gfx.setfont(FONT_EMPH); local lw = ui_text_w(line1); gfx.setfont(FONT_BODY)
        ui_text_l(xbase + ui_pt(9) + lw + ui_pt(4), ybase + ui_pt(5), ui_pt(16), nn)
        ui_col(T.TEXT_SECONDARY)
        ui_text_l(xbase + ui_pt(9), ybase + ui_pt(22), ui_pt(15), line2)
        gfx.setfont(FONT_BASE)
      end
      return hide
    end

    -- from ReEQ2 2.1.0: draw_listen_helper(), for a band being heard (listen_node, or the hovered band
    -- while Shift is held; the free Shift-drag listen follows the mouse and isn't translated). It sets
    -- the listen filter, then draws the range lines when draw is true: render() also runs it before
    -- the analyser, as ReEQ2's previous frame did, so the listen spectrum has its filter.
    local function draw_listen_helper(draw)
      ui_cola(T.LISTEN, 1)
      local node = node_hover
      if listen_node ~= -1 then node = listen_node end
      if node < 0 then return end
      local t = Band_Type[node]
      local bottom = gfx_h - BOTTOM_MARGIN

      listen_freq = Band_Frequency[node]
      listen_q = Band_Q[node]
      listen_group = Band_Group[node]
      local width = ivf_qtobw(listen_q)

      -- Peak or notch? - Has a wider band range
      if t == FILTER_PEAK or t == FILTER_NOTCH then width = width * 2 end

      local lfreq = listen_freq / (2 ^ (width / 2))
      local rfreq = listen_freq * (2 ^ (width / 2))
      local lx = spectrum.freq_to_x(lfreq)
      local rx = spectrum.freq_to_x(rfreq)

      listen_q = ivf_bwtoq(width)

      -- Peak, Band Pass or Notch?
      if t == FILTER_PEAK or t == FILTER_BAND_PASS or t == FILTER_NOTCH then
        if t == FILTER_PEAK then
          local gain = Band_Enabled[node] == BAND_STATE_ENABLED and Band_Gain[node] or 0
          listen_filter:ivf_listen_bell(lfreq, rfreq, Band_Frequency[node], Band_Q[node], gain)
        elseif t == FILTER_BAND_PASS then
          listen_filter:ivf_listen_notch(lfreq, rfreq, Band_Frequency[node], Band_Q[node])
        else
          listen_filter:ivf_band_pass(listen_freq, Band_Q[node])
        end

        if draw then
          ui_cola(T.LISTEN, 1)
          gfx.line(lx, 0, lx, bottom, 1)
          gfx.line(rx, 0, rx, bottom, 1)

          ui_cola(T.LISTEN, 0.8)
          gfx.line(lx - 1, 0, lx - 1, bottom, 1)
          gfx.line(rx + 1, 0, rx + 1, bottom, 1)

          ui_cola(T.LISTEN_SHADOW, 1)
          gfx.rect(lx - 3, 0, 2, bottom, 1)

          ui_cola(T.LISTEN_SHADOW, 1)
          gfx.rect(rx + 2, 0, 2, bottom, 1)
        end
      else
        -- Cut or shelf
        ui_cola(T.LISTEN, 1)
        lx = spectrum.freq_to_x(listen_freq)

        if t == FILTER_LOW_CUT then listen_filter:ivf_high_cut(listen_freq, Band_Q[node], Band_Slope[node]) end
        if t == FILTER_LOW_CUT_BUTTERWORTH then listen_filter:ivf_high_cut_bwq(listen_freq, Band_Q[node], Band_Slope[node]) end

        if t == FILTER_LOW_CUT_ANALOG then listen_filter:ivf_high_cut(listen_freq, 0.701, 3) end
        if t == FILTER_HIGH_CUT_ANALOG then listen_filter:ivf_low_cut(listen_freq, 0.701, 3) end

        if t == FILTER_LOW_SHELF then
          lx = spectrum.freq_to_x(rfreq)
          rfreq = min(max(rfreq, 10), MAX_FREQ)
          listen_filter:ivf_high_cut_bw(rfreq, 3)
        end
        if t == FILTER_HIGH_SHELF then
          lx = spectrum.freq_to_x(lfreq)
          lfreq = min(max(lfreq, 10), MAX_FREQ)
          listen_filter:ivf_low_cut_bw(lfreq, 3)
        end

        if t == FILTER_HIGH_CUT then listen_filter:ivf_low_cut(listen_freq, Band_Q[node], Band_Slope[node]) end
        if t == FILTER_HIGH_CUT_BUTTERWORTH then listen_filter:ivf_low_cut_bwq(listen_freq, Band_Q[node], Band_Slope[node]) end

        if t == FILTER_TILT_SHELF or t == FILTER_ALL_PASS then listen_filter:ivf_bypass() end

        if t == FILTER_PULTEC_LOW_SHELF then
          -- Pultec style - maybe we can do better?
          lx = spectrum.freq_to_x(rfreq)
          rfreq = min(max(rfreq, 10), MAX_FREQ)
          listen_filter:ivf_high_cut_bw(rfreq, 3)
        end

        if draw and t ~= FILTER_TILT_SHELF and t ~= FILTER_ALL_PASS then gfx.line(lx, 0, lx, bottom, 1) end
      end
      -- At rest: the audio's glide to the new filter has ended
      listen_filter:ivf_set_to_target()
    end

    return draw_listen_helper, draw_info_panel, draw_dyn_detectors, draw_dyn_ghost, dyn_ghost_ok, dyn_det_freq, dyn_det_q
  end)()

  ------------------------------------------------------------------------------------------------
  -- The chrome: header, top-right buttons, toolbar and the band panel ("UI: bottom toolbar, top-right
  -- controls, node panel and pickers"), with their widgets. Nothing is hovered, dragged or open.
  ------------------------------------------------------------------------------------------------

  local ui_draw_header, ui_draw_top, ui_draw_bar, ui_draw_panel = (function()
    local MIN_Q, MAX_Q = 0.10, 40
    local Q_LOG_MAX = log(MAX_Q / MIN_Q)
    local BAND_GAIN_MAX, DYN_THRESH_MIN, DYN_RATIO_MAX, DYN_RANGE_MAX = 30, -60, 20, 24
    local DYN_ATK_MIN, DYN_ATK_MAX, DYN_REL_MIN, DYN_REL_MAX = 0.1, 200, 5, 2000
    -- The toolbar: M/S (Stereo_Mode 0), every trim at 0 dB, Limit and Auto off, the meters at rest
    local Stereo_Mode, InGain, MLGain, SRGain, Gain = 0, 0, 0, 0, 0
    local LimitOutput, AutoGainEnabled, MidPolarity, SidePolarity, AG_Target = 0, 0, 0, 0, 1
    local ui_ipk0, ui_ipk1, ui_pk0, ui_pk1, ui_clip_in, ui_clip_out = 0, 0, 0, 0, 0, 0

    -- from ReEQ2 2.3.0: ui_shape_name() (types 1 and 5 are the legacy resonant cuts)
    local function ui_shape_name(t)
      local names = { [0] = "Bell", "Low Cut", "Low Cut", "Low Shelf", "High Shelf", "High Cut", "High Cut", "Notch",
        "Band Pass", "Tilt Shelf", "Pultec Low", "All Pass", "Vintage Lo" }
      return names[t] or "Vintage Hi"
    end

    -- from ReEQ2 2.1.0: ui_gain_inert(), ui_group_name(); from 2.3.0: ui_q_inert()
    local function ui_gain_inert(t)
      return t == FILTER_NOTCH or t == FILTER_BAND_PASS or t == FILTER_ALL_PASS
    end

    local function ui_q_inert(b)
      local t = Band_Type[b]
      return t == FILTER_LOW_CUT_ANALOG or t == FILTER_HIGH_CUT_ANALOG or (ui_is_cut(t) and Band_Slope[b] == 0)
    end

    local function ui_group_name(g)
      return g == 0 and "Stereo" or g == 1 and "Mid" or g == 2 and "Side" or g == 3 and "Left" or "Right"
    end

    -- from ReEQ2 2.1.0: freq_to_per(), q_to_per()
    local function freq_to_per(freq, range)
      return range * log(freq / MIN_FREQ) / FREQ_LOG_MAX
    end

    local function q_to_per(q, range)
      return range * log(q / MIN_Q) / Q_LOG_MAX
    end

    -- from ReEQ2 2.1.0: band_dyn_auto_attack(), band_dyn_auto_release()
    local function band_dyn_auto_attack(b)
      local f = dyn_det_freq(b)
      return min(max(1000 * (1.5 / f + dyn_det_q(b) / (PI * f)) + 0.5, 0.5), 30)
    end

    local function band_dyn_auto_release(b)
      return min(max(8 * band_dyn_auto_attack(b), 25), 300)
    end

    -- from ReEQ2 2.1.0: ui_fmt_ms()
    local function ui_fmt_ms(v)
      return string.format(v < 10 and "%.1f" or "%.0f", v)
    end

    -- from ReEQ2 2.1.0: ui_dial()
    local function ui_dial(cx, cy, v, bipolar, nd, dim)
      local s = ui_pt(1)
      cx = floor(cx) + 0.5; cy = floor(cy) + 0.5
      ui_mix = dim and 0.65 or 0
      gfx.a = 1

      -- Detents
      if nd > 1 then
        local cur = floor(v * (nd - 1) + 0.5)
        for k = 0, nd - 1 do
          local th = 0.75 * PI + 1.5 * PI * k / (nd - 1)
          local x, y = cx + 32.2 * s * cos(th), cy + 32.2 * s * sin(th)
          if k == cur then
            ui_band_col(selected_node); gfx.circle(x, y, 1.6 * s, 1, 1)
          else
            ui_col(T.DIAL_EDGE); gfx.circle(x, y, 1.2 * s, 1, 1)
          end
        end
      end

      -- Halo track and value
      ui_col(T.DIAL_TRACK)
      ui_thick_arc(cx, cy, 29 * s, 1.25 * PI, 2.75 * PI, 2 * s)
      local t0, t1
      if bipolar then t0 = min(0.5, v); t1 = max(0.5, v) else t0 = 0; t1 = v end
      if t1 - t0 > 0.004 then
        ui_band_col(selected_node)
        ui_thick_arc(cx, cy, 29 * s, 1.25 * PI + 1.5 * PI * t0, 1.25 * PI + 1.5 * PI * t1, 2 * s)
      end

      -- Rim and a very soft radial face, lit from up and left
      ui_col(T.DIAL_RIM); gfx.circle(cx, cy, 21 * s, 1, 1)
      local n = 10
      for i = 0, n - 1 do
        local t = i / n
        local rr = 20 * s * (1 - t * 0.85)
        ui_col_mix(T.DIAL_FACE, T.DIAL_FACE_LIT, t, 1)
        gfx.circle(cx - 3.2 * s * t, cy - 5.6 * s * t, rr, 1, 1)
      end
      ui_col(T.DIAL_EDGE); gfx.circle(cx, cy, 19.5 * s, 0, 1)

      -- Pointer with a soft shadow
      local th = 0.75 * PI + 1.5 * PI * v
      ui_col(T.DIAL_SHADOW)
      ui_thick_line(cx + 7 * s * cos(th) + 0.8 * s, cy + 7 * s * sin(th) + 0.8 * s, cx + 16 * s * cos(th) + 0.8 * s, cy + 16 * s * sin(th) + 0.8 * s, 2.4 * s)
      ui_col(T.DIAL_POINTER)
      ui_thick_line(cx + 7 * s * cos(th), cy + 7 * s * sin(th), cx + 16 * s * cos(th), cy + 16 * s * sin(th), 2 * s)
      ui_mix = 0
    end

    -- from ReEQ2 2.1.0: ui_icon()
    local function ui_icon(kind, cx, cy)
      local s = ui_pt(1); local w = 1.4 * s
      if kind == 1 then
        ui_thick_arc(cx, cy + 1 * s, 5 * s, -0.5 * PI, 0.5 * PI, w)
        ui_thick_line(cx - 5 * s, cy + 1 * s, cx - 5 * s, cy + 2.5 * s, w)
        ui_thick_line(cx + 5 * s, cy + 1 * s, cx + 5 * s, cy + 2.5 * s, w)
        gfx.roundrect(cx - 5.5 * s, cy + 1.5 * s, 2.5 * s, 4 * s, s, 1)
        gfx.roundrect(cx + 3 * s, cy + 1.5 * s, 2.5 * s, 4 * s, s, 1)
      elseif kind == 2 then
        ui_thick_arc(cx, cy + 0.8 * s, 4.5 * s, 0.22 * PI, 1.78 * PI, w)
        ui_thick_line(cx, cy - 5.2 * s, cx, cy - 0.3 * s, w)
      elseif kind == 3 then
        gfx.roundrect(cx - 2.5 * s, cy - 2.5 * s, 8 * s, 8 * s, 1.5 * s, 1)
        ui_thick_line(cx + 2.5 * s, cy - 2.5 * s, cx + 2.5 * s, cy - 5 * s, w)
        ui_thick_line(cx + 2.5 * s, cy - 5.5 * s, cx - 5 * s, cy - 5.5 * s, w)
        ui_thick_line(cx - 5.5 * s, cy - 5.5 * s, cx - 5.5 * s, cy + 2 * s, w)
        ui_thick_line(cx - 5.5 * s, cy + 2.5 * s, cx - 3 * s, cy + 2.5 * s, w)
      elseif kind == 4 then
        ui_thick_line(cx - 5 * s, cy - 3.5 * s, cx + 5 * s, cy - 3.5 * s, w)
        ui_thick_line(cx - 1.5 * s, cy - 3.5 * s, cx - 1.5 * s, cy - 5 * s, w)
        ui_thick_line(cx - 1.5 * s, cy - 5 * s, cx + 1.5 * s, cy - 5 * s, w)
        ui_thick_line(cx + 1.5 * s, cy - 5 * s, cx + 1.5 * s, cy - 3.5 * s, w)
        ui_thick_line(cx - 3.5 * s, cy - 3.5 * s, cx - 2.9 * s, cy + 5 * s, w)
        ui_thick_line(cx - 2.9 * s, cy + 5 * s, cx + 2.9 * s, cy + 5 * s, w)
        ui_thick_line(cx + 2.9 * s, cy + 5 * s, cx + 3.5 * s, cy - 3.5 * s, w)
      elseif kind == 5 then
        ui_thick_arc(cx, cy, 2.2 * s, 0, 2 * PI, w)
        for k = 0, 7 do
          local a = k * PI / 4
          ui_thick_line(cx + 3.7 * s * sin(a), cy - 3.7 * s * cos(a), cx + 5.5 * s * sin(a), cy - 5.5 * s * cos(a), w)
        end
      elseif kind == 6 then
        -- The outer ear from its front edge over the top, then down to the lobe; the inner fold
        local ex, ey = cx + 0.5 * s, cy - 1.5 * s
        local a = 2.62 * PI
        ui_thick_arc(ex, ey, 4.5 * s, 1.5 * PI, a, w)
        local x1, y1 = ex + 4.5 * s * sin(a), ey - 4.5 * s * cos(a)
        ui_thick_line(x1, y1, cx + 1.8 * s, cy + 3.2 * s, w)
        ui_thick_line(cx + 1.8 * s, cy + 3.2 * s, cx - 0.6 * s, cy + 5.4 * s, w)
        ui_thick_line(cx - 0.6 * s, cy + 5.4 * s, cx - 2.8 * s, cy + 4.6 * s, w)
        ui_thick_arc(ex, ey, 2 * s, 1.5 * PI, 2.4 * PI, w)
      elseif kind == 7 or kind == 8 then
        -- Two chain links, joined, or pulled apart
        local k = kind == 7 and 0 or 1.5 * s
        local a = floor(2.5 * s)
        gfx.roundrect(floor(cx - 6.5 * s - k), floor(cy - 2.5 * s), floor(8 * s), floor(5 * s), a, 1)
        gfx.roundrect(floor(cx - 6.5 * s - k) + 1, floor(cy - 2.5 * s) + 1, floor(8 * s) - 2, floor(5 * s) - 2, a - 1, 1)
        gfx.roundrect(floor(cx - 1.5 * s + k), floor(cy - 2.5 * s), floor(8 * s), floor(5 * s), a, 1)
        gfx.roundrect(floor(cx - 1.5 * s + k) + 1, floor(cy - 2.5 * s) + 1, floor(8 * s) - 2, floor(5 * s) - 2, a - 1, 1)
      elseif kind == 9 then
        -- Revert: an arc over the top from the left, coming back down to an arrowhead on the left
        ui_thick_arc(cx + 0.5 * s, cy + 0.5 * s, 4.5 * s, 1.5 * PI, 2.8 * PI, w)
        local ex, ey = cx - 4 * s, cy + 0.5 * s
        gfx.triangle(ex - 2.6 * s, ey - 0.6 * s, ex + 2.6 * s, ey - 0.6 * s, ex, ey + 2.8 * s)
      elseif kind == 10 then
        -- Close: a cross
        ui_thick_line(cx - 4 * s, cy - 4 * s, cx + 4 * s, cy + 4 * s, w)
        ui_thick_line(cx - 4 * s, cy + 4 * s, cx + 4 * s, cy - 4 * s, w)
      end
    end

    -- from ReEQ2 2.1.0: ui_button_draw(), ui_button() (style 0 normal, 1 on, 2 danger on hover)
    local function ui_button_draw(x, y, w, h, label, style, hov)
      if style == 1 then
        ui_box(x, y, w, h, ui_pt(5), T.ACCENT_FILL, 1, T.ACCENT_BORDER)
      elseif style == 2 and hov then
        ui_box(x, y, w, h, ui_pt(5), T.DANGER_FILL, 1, T.DANGER_BORDER)
      else
        ui_box(x, y, w, h, ui_pt(5), hov and T.CONTROL_HOVER or T.CONTROL, 1, T.BORDER)
      end
      if #label > 0 then
        gfx.setfont(style == 1 and FONT_BODY_B or FONT_BODY)
        ui_col(style == 1 and T.ACCENT or hov and T.TEXT or T.TEXT_DIM)
        ui_text_c(x, y, w, h, label)
      end
    end

    local function ui_button(x, y, w, h, label, style)
      ui_button_draw(x, y, w, h, label, style, false)
    end

    -- from ReEQ2 2.1.0: ui_icon_button_draw(), ui_icon_button()
    local function ui_icon_button_draw(x, y, w, h, kind, style, hov)
      ui_button_draw(x, y, w, h, "", style, hov)
      ui_col(style == 1 and T.ACCENT or (style == 2 and hov) and T.DANGER or hov and T.TEXT or T.TEXT_SECONDARY)
      ui_icon(kind, x + w * 0.5, y + h * 0.5)
    end

    local function ui_icon_button(x, y, w, h, kind, style)
      ui_icon_button_draw(x, y, w, h, kind, style, false)
    end

    -- from ReEQ2 2.1.0: ui_dropdown()
    local function ui_dropdown(x, y, w, h, label, open)
      local hov = false
      if open then
        ui_box(x, y, w, h, ui_pt(5), T.ACCENT_FILL, 1, T.ACCENT_BORDER)
      else
        ui_box(x, y, w, h, ui_pt(5), hov and T.CONTROL_HOVER or T.CONTROL, 1, T.BORDER)
      end
      gfx.setfont(FONT_BODY)
      ui_col(T.TEXT)
      ui_text_l(x + ui_pt(9), y, h, label)
      ui_col(open and T.ACCENT or T.TEXT_FAINT)
      ui_chevron(x + w - ui_pt(11), y + h * 0.5, ui_pt(3), open and -1 or 1)
    end

    -- from ReEQ2 2.1.0: ui_seg2()
    local function ui_seg2(x, y, h, w0, w1, l0, l1, sel)
      local r = ui_pt(5)
      local hov0, hov1 = false, false
      ui_cola(T.CONTROL, 1); ui_fill_rrect(x, y, w0 + w1, h, r)
      ui_cola(T.ACCENT_FILL, 1)
      -- The active segment is a rounded box overlapping its neighbour, with the overlap painted back
      if sel == 0 then
        ui_fill_rrect(x, y, w0 + r, h, r); ui_col(T.CONTROL); gfx.rect(x + w0, y, r, h, 1)
      else
        ui_fill_rrect(x + w0 - r, y, w1 + r, h, r); ui_col(T.CONTROL); gfx.rect(x + w0 - r, y, r, h, 1)
      end
      ui_cola(T.BORDER, 1)
      gfx.roundrect(x, y, w0 + w1 - 1, h - 1, r, 1)
      gfx.line(x + w0, y, x + w0, y + h - 1, 0)

      gfx.setfont(sel == 0 and FONT_BODY_B or FONT_BODY)
      ui_col(sel == 0 and T.ACCENT or hov0 and T.TEXT or T.TEXT_DIM)
      ui_text_c(x, y, w0, h, l0)
      gfx.setfont(sel == 1 and FONT_BODY_B or FONT_BODY)
      ui_col(sel == 1 and T.ACCENT or hov1 and T.TEXT or T.TEXT_DIM)
      ui_text_c(x + w0, y, w1, h, l1)
    end

    -- from ReEQ2 2.1.0: ui_field()
    local function ui_field(x, y, w, h, label, val, unit, hot)
      ui_box(x, y, w, h, ui_pt(5), T.CONTROL, 1, hot and T.BORDER_HOVER or T.BORDER)
      local tx = x + ui_pt(9)
      if #label > 0 then
        gfx.setfont(FONT_CAP); ui_col(T.TEXT_FAINT)
        ui_text_l(tx, y, h, label)
        tx = tx + ui_text_w(label) + ui_pt(7)
      end
      gfx.setfont(FONT_BODY_B); ui_col(T.TEXT)
      ui_text_l(tx, y, h, val)
      tx = tx + ui_text_w(val)
      if #unit > 0 then
        gfx.setfont(FONT_BODY); ui_col(T.TEXT_DIM)
        tx = tx + ui_pt(3)
        ui_text_l(tx, y, h, unit)
        tx = tx + ui_text_w(unit)
      end
      return tx
    end

    -- from ReEQ2 2.1.0: ui_text_button()
    local function ui_text_button(x, y, w, h, label)
      local hov = false
      gfx.setfont(FONT_EMPH)
      ui_col(hov and T.TEXT or T.TEXT_SECONDARY)
      ui_text_c(x, y, w, h, label)
    end

    -- from ReEQ2 2.1.0: ui_dial_face()
    local function ui_dial_face(cx, cy, label, v, bipolar, nd, dim, val, unit)
      local s = ui_pt(1)
      local a = dim and 0.35 or 1
      gfx.setfont(FONT_CAP); ui_col_a(T.TEXT_DIM, a)
      ui_text_c(cx - 60 * s, cy - 50 * s, 120 * s, 12 * s, label)
      ui_dial(cx, cy, v, bipolar, nd, dim)
      gfx.setfont(FONT_EMPH); local w1 = ui_text_w(val)
      gfx.setfont(FONT_BODY); local w2 = #unit > 0 and ui_text_w(unit) + 3 * s or 0
      local x = cx - (w1 + w2) * 0.5
      gfx.setfont(FONT_EMPH); ui_col_a(T.TEXT, a)
      ui_text_l(x, cy + 34 * s, 16 * s, val)
      if #unit > 0 then
        gfx.setfont(FONT_BODY); ui_col_a(T.TEXT_DIM, a)
        ui_text_l(x + w1 + 3 * s, cy + 34 * s, 16 * s, unit)
      end
      gfx.a = 1
    end

    -- from ReEQ2 2.1.0: ui_meter_seg()
    local function ui_meter_seg(bx, by, bw, bh, fw, f0, f1, t0, t1)
      local x0, x1 = bx + f0 * bw, bx + f1 * bw
      local xc = min(x1, bx + fw)
      local span = max(x1 - x0, 1)
      local p, q = Pal[t0], Pal[t1]
      if xc > x0 then
        gradrect(t0, floor(x0), by, max(1, ceil(xc - x0)), bh, p[1] / 255, p[2] / 255, p[3] / 255, p[4],
          (q[1] - p[1]) / 255 / span, (q[2] - p[2]) / 255 / span, (q[3] - p[3]) / 255 / span, 0, 0, 0, 0, 0)
      end
    end

    -- from ReEQ2 2.1.0: ui_meter()
    local function ui_meter(x, y, w, h, mw, p0, p1)
      local bx = floor(x + w - ui_pt(7) - mw)
      local bh = max(1, floor(ui_pt(3)))
      local q12, q3, q0 = 48 / 63, 57 / 63, 60 / 63
      for k = 0, 1 do
        local by = floor(y + h * 0.5 - ui_pt(4) + k * ui_pt(5))
        ui_col(T.DIAL_TRACK)
        gfx.rect(bx, by, mw, bh, 1)
        local lv = 20 * log10(max(k == 0 and p0 or p1, 0.000001))
        local fr = min(max((lv + 60) / 63, 0), 1)
        local fw = floor(mw * fr)
        if fw > 0 then
          ui_meter_seg(bx, by, mw, bh, fw, 0, q12, T.METER_OK, T.METER_OK)
          ui_meter_seg(bx, by, mw, bh, fw, q12, q3, T.METER_OK, T.METER_WARN)
          ui_meter_seg(bx, by, mw, bh, fw, q3, q0, T.METER_WARN, T.CLIP)
          ui_meter_seg(bx, by, mw, bh, fw, q0, 1, T.CLIP, T.CLIP)
        end
      end
    end

    -- from ReEQ2 2.1.0: ui_clip_glow()
    local function ui_clip_glow(x, y, w, h, glow)
      if glow > 0.001 then
        ui_cola(T.CLIP, 0.10 * glow); ui_fill_rrect(x, y, w, h, ui_pt(5))
        ui_cola(T.CLIP, glow); gfx.roundrect(floor(x), floor(y), floor(w) - 1, floor(h) - 1, ui_pt(5), 1)
        gfx.a = 1
      end
    end

    -- from ReEQ2 2.1.0: ui_knob_small()
    local function ui_knob_small(cx, cy, v, bipolar, grey, dim)
      local s = ui_pt(1)
      cx = floor(cx) + 0.5; cy = floor(cy) + 0.5
      ui_mix = dim and 0.65 or 0
      gfx.a = 1
      ui_col(T.DIAL_TRACK)
      ui_thick_arc(cx, cy, 12 * s, 1.25 * PI, 2.75 * PI, 2 * s)
      local t0, t1
      if bipolar then t0 = min(0.5, v); t1 = max(0.5, v) else t0 = 0; t1 = v end
      if t1 - t0 > 0.004 then
        if grey then ui_col(T.TEXT_DIM) else ui_band_col(selected_node) end
        ui_thick_arc(cx, cy, 12 * s, 1.25 * PI + 1.5 * PI * t0, 1.25 * PI + 1.5 * PI * t1, 2 * s)
      end
      ui_col(T.DIAL_RIM); gfx.circle(cx, cy, 9 * s, 1, 1)
      ui_col(T.DIAL_FACE); gfx.circle(cx, cy, 8 * s, 1, 1)
      ui_col(T.DIAL_EDGE); gfx.circle(cx, cy, 8 * s, 0, 1)
      local th = 0.75 * PI + 1.5 * PI * v
      ui_col(T.DIAL_POINTER)
      ui_thick_line(cx + 2.5 * s * cos(th), cy + 2.5 * s * sin(th), cx + 7 * s * cos(th), cy + 7 * s * sin(th), 1.6 * s)
      ui_mix = 0
    end

    -- from ReEQ2 2.1.0: ui_dyn_cell() (drawing only)
    local function ui_dyn_cell(id, x, cy, w, label, v, bipolar, grey, dim, val, unit)
      local s = ui_pt(1)
      ui_knob_small(x + 13 * s, cy, v, bipolar, grey, dim)
      gfx.a = 1; ui_mix = dim and 0.65 or 0
      local tx = x + 31 * s
      gfx.setfont(FONT_CAP); ui_col(T.TEXT_DIM)
      ui_text_l(tx, cy - 13 * s, 10 * s, label)
      gfx.setfont(FONT_BODY_B); ui_col(T.TEXT)
      ui_text_l(tx, cy - 2 * s, 14 * s, val)
      local w1 = ui_text_w(val)
      if #unit > 0 then gfx.setfont(FONT_CAP); ui_col(T.TEXT_DIM); ui_text_l(tx + w1 + 2 * s, cy - 2 * s, 14 * s, unit) end
      ui_mix = 0
      return v
    end

    -- from ReEQ2 2.1.0: ui_dyn_timing() (drawing only)
    local function ui_dyn_timing(x, cy, w, b)
      local s = ui_pt(1)
      local on = Band_Dyn_Auto[b] ~= 0
      local hov = false
      local sx = x + 1 * s
      if on then
        ui_box(sx, cy - 8 * s, 28 * s, 16 * s, 8 * s, T.ACCENT_FILL, 1, T.ACCENT_BORDER)
      else
        ui_box(sx, cy - 8 * s, 28 * s, 16 * s, 8 * s, T.CONTROL, 1, hov and T.BORDER_HOVER or T.BORDER)
      end
      ui_col(on and T.ACCENT or T.TEXT_DIM)
      gfx.circle(on and sx + 20 * s or sx + 8 * s, cy, 5 * s, 1, 1)
      local tx = x + 35 * s
      gfx.setfont(FONT_CAP); ui_col(T.TEXT_DIM)
      ui_text_l(tx, cy - 13 * s, 10 * s, "TIMING")
      gfx.setfont(FONT_BODY_B); ui_col(on and T.ACCENT or hov and T.TEXT or T.TEXT_SECONDARY)
      ui_text_l(tx, cy - 2 * s, 14 * s, on and "Auto" or "Manual")
    end

    -- from ReEQ2 2.1.0: ui_dyn_meter() (the level as the meter first shows it: Band_Dyn_Level)
    local function ui_dyn_meter(mx, y, b)
      local s = ui_pt(1)
      local top, mh = y + 56 * s, 62 * s
      gfx.a = 1
      gfx.setfont(FONT_CAP); ui_col(T.TEXT_DIM)
      ui_text_c(mx - 16 * s, y + 42 * s, 32 * s, 10 * s, "GR")

      local ui_dyn_lv = Band_Dyn_Level[b]
      ui_col(T.DIAL_TRACK)
      gfx.rect(mx - 6 * s, top, 4 * s, mh, 1)
      gfx.rect(mx + 1 * s, top, 5 * s, mh, 1)
      local f = min(max((ui_dyn_lv + 60) / 60, 0), 1)
      ui_col(T.TEXT_DIM)
      if f > 0 then gfx.rect(mx - 6 * s, top + mh * (1 - f), 4 * s, mh * f, 1) end
      local t = min(max((Band_Dyn_Thresh[b] + 60) / 60, 0), 1)
      ui_band_col(b)
      gfx.rect(mx - 8 * s, floor(top + mh * (1 - t)), 8 * s, max(1, floor(1.5 * s)), 1)

      local g = Band_Dyn_Gain[b]
      f = min(abs(g) / max(abs(Band_Dynamic_Range[b]), 0.1), 1)
      if f > 0.005 then
        if Band_Dynamic_Range[b] < 0 then gfx.rect(mx + 1 * s, top, 5 * s, mh * f, 1) else gfx.rect(mx + 1 * s, top + mh * (1 - f), 5 * s, mh * f, 1) end
      end
      gfx.setfont(FONT_CAP); ui_col(T.TEXT)
      ui_text_c(mx - 16 * s, top + mh + 4 * s, 32 * s, 14 * s, ui_fmt_db(g))
    end

    -- from ReEQ2 2.1.0: ui_draw_dyn_block() (drawing only)
    local function ui_draw_dyn_block(b, hl, y, xr)
      local s = ui_pt(1)
      ui_col(T.BORDER_SUBTLE)
      gfx.line(hl, y + 46 * s, hl, y + 136 * s, 0)
      local gx, cw, r1, r2 = hl + 12 * s, 92 * s, y + 68 * s, y + 116 * s
      local auto = Band_Dyn_Auto[b] ~= 0

      -- Threshold, -60..0dB
      local v = 1 - Band_Dyn_Thresh[b] / DYN_THRESH_MIN
      ui_dyn_cell(0, gx, r1, cw, "THRESHOLD", v, false, false, false, ui_fmt_db(Band_Dyn_Thresh[b]), "dB")

      -- Ratio, 1..20, on a log scale
      local lr = log(DYN_RATIO_MAX)
      v = log(max(Band_Dyn_Ratio[b], 1)) / lr
      ui_dyn_cell(1, gx + cw, r1, cw, "RATIO", v, false, false, false,
        string.format(Band_Dyn_Ratio[b] < 10 and "%.1f" or "%.0f", Band_Dyn_Ratio[b]), ":1")

      -- Range, -24..+24dB: its sign is the direction
      v = (Band_Dynamic_Range[b] / DYN_RANGE_MAX + 1) * 0.5
      ui_dyn_cell(2, gx + 2 * cw, r1, cw, "RANGE", v, true, false, false, ui_fmt_db(Band_Dynamic_Range[b]), "dB")

      -- Attack and release on log scales; with Auto on they show the automatic times, greyed
      local a = auto and band_dyn_auto_attack(b) or Band_Dyn_Attack[b]
      lr = log(DYN_ATK_MAX / DYN_ATK_MIN)
      v = log(a / DYN_ATK_MIN) / lr
      ui_dyn_cell(3, gx, r2, cw, "ATTACK", v, false, auto, auto, ui_fmt_ms(a), "ms")

      a = auto and band_dyn_auto_release(b) or Band_Dyn_Release[b]
      lr = log(DYN_REL_MAX / DYN_REL_MIN)
      v = log(a / DYN_REL_MIN) / lr
      ui_dyn_cell(4, gx + cw, r2, cw, "RELEASE", v, false, auto, auto, ui_fmt_ms(a), "ms")

      ui_dyn_timing(gx + 2 * cw, r2, cw, b)
      ui_dyn_meter(xr - 24 * s, y, b)
    end

    -- from ReEQ2 2.1.0: ui_draw_bar() (drawing only)
    local function ui_draw_bar()
      local s = ui_pt(1)
      local bh = ui_pt(40); local y0 = gfx_h - bh
      local h = ui_pt(24); local y = floor(y0 + (bh - h) * 0.5)
      local pol, gg, pad = ui_pt(22), ui_pt(16), ui_pt(14)

      ui_cola(T.BAR, 1); gfx.rect(0, y0, gfx_w, bh, 1)
      ui_cola(T.BORDER_SUBTLE, 1); gfx.line(0, y0, gfx_w, y0, 0)

      local sc = string.format("%d%%", floor(Scale))
      local inv, midv, sidev, outv = ui_fmt_db(InGain), ui_fmt_db(MLGain), ui_fmt_db(SRGain), ui_fmt_db(Gain)
      local ag = AutoGainEnabled ~= 0 and string.format("Auto %s dB", ui_fmt_db(20 * log10(AG_Target))) or "Auto"

      -- Pick the densest layout that fits: full, then without units, then without labels
      local d = 0
      local labels, units, gap, mw, w_in, w_lr, w_ms, w_sc, w_mid, w_side, w_lim, w_auto, w_pan, w_out, wl, wc, wr
      repeat
        labels = d < 2; units = d == 0
        gap = d == 0 and ui_pt(8) or d == 1 and ui_pt(6) or d == 2 and ui_pt(4) or ui_pt(3)
        mw = d == 0 and ui_pt(34) or d == 1 and ui_pt(24) or d == 2 and ui_pt(18) or ui_pt(12)
        -- Tightest: Auto without its value, and smaller margins
        if d == 3 then ag = "Auto"; gg = ui_pt(8); pad = ui_pt(8) end

        gfx.setfont(FONT_BODY_B)
        w_lr = ui_text_w("L/R") + ui_pt(18); w_ms = ui_text_w("M/S") + ui_pt(18)
        -- Widths come from templates, not the live values, so nothing moves while a value is dragged
        local k = max(ui_text_w("+00.0"), ui_text_w("−000.0"))
        w_sc = max(ui_text_w("200%"), ui_text_w(sc))
        w_mid = max(k, ui_text_w(midv)); w_side = max(k, ui_text_w(sidev)); w_out = max(k, ui_text_w(outv)); w_in = max(k, ui_text_w(inv))
        w_auto = ((AutoGainEnabled ~= 0 and d < 3) and max(ui_text_w("Auto −000.0 dB"), ui_text_w(ag)) or ui_text_w(ag)) + ui_pt(18)
        gfx.setfont(FONT_BODY)
        w_lim = ui_text_w("Limit") + ui_pt(18); w_pan = ui_text_w("Panel") + ui_pt(18)
        if units then
          k = ui_text_w("dB") + ui_pt(3)
          w_mid = w_mid + k; w_side = w_side + k; w_out = w_out + k; w_in = w_in + k
        end
        gfx.setfont(FONT_CAP)
        if labels then
          w_sc = w_sc + ui_text_w("SCALE") + ui_pt(7)
          w_mid = w_mid + ui_text_w(Stereo_Mode ~= 0 and "LEFT" or "MID") + ui_pt(7)
          w_side = w_side + ui_text_w(Stereo_Mode ~= 0 and "RIGHT" or "SIDE") + ui_pt(7)
          w_out = w_out + ui_text_w("OUT") + ui_pt(7)
          w_in = w_in + ui_text_w("IN") + ui_pt(7)
        end
        w_sc = w_sc + ui_pt(18); w_mid = w_mid + ui_pt(16) + pol; w_side = w_side + ui_pt(16) + pol
        w_out = w_out + ui_pt(23) + mw; w_in = w_in + ui_pt(23) + mw

        -- Input on the left; scale and the stereo controls (selector first) in the centre; output on the right
        wl = w_in
        wc = w_sc + gap + w_lr + w_ms + gap + w_mid + gap + w_side
        wr = w_lim + gap + w_auto + gap + w_pan + gap + w_out
        d = d + 1
      until not (d < 4 and wl + wc + wr + 2 * gg + 2 * pad > gfx_w)

      local xl = pad
      local xr = gfx_w - pad - wr
      local xc = floor(gfx_w * 0.5 - wc * 0.5)
      xc = max(xl + wl + gg, min(xc, xr - gg - wc))

      -- Input trim with its peak meter
      local x = xl
      ui_field(x, y, w_in, h, labels and "IN" or "", inv, units and "dB" or "", false)
      ui_clip_glow(x, y, w_in, h, ui_clip_in)
      ui_meter(x, y, w_in, h, mw, ui_ipk0, ui_ipk1)

      -- Scale, then the stereo controls: L/R | M/S (Stereo_Mode 0 is M/S, 1 is L/R) and its two trims
      x = xc
      ui_field(x, y, w_sc, h, labels and "SCALE" or "", sc, "", false)

      x = x + w_sc + gap
      ui_seg2(x, y, h, w_lr, w_ms, "L/R", "M/S", Stereo_Mode ~= 0 and 0 or 1)

      x = x + w_lr + w_ms + gap
      ui_field(x, y, w_mid, h, labels and (Stereo_Mode ~= 0 and "LEFT" or "MID") or "", midv, units and "dB" or "", false)
      ui_col(T.BORDER); gfx.line(x + w_mid - pol, y + 1, x + w_mid - pol, y + h - 2, 0)
      ui_col(MidPolarity ~= 0 and T.ACCENT or T.TEXT_DIM)
      gfx.setfont(FONT_BODY); ui_text_c(x + w_mid - pol, y, pol, h, "ø")

      x = x + w_mid + gap
      ui_field(x, y, w_side, h, labels and (Stereo_Mode ~= 0 and "RIGHT" or "SIDE") or "", sidev, units and "dB" or "", false)
      ui_col(T.BORDER); gfx.line(x + w_side - pol, y + 1, x + w_side - pol, y + h - 2, 0)
      ui_col(SidePolarity ~= 0 and T.ACCENT or T.TEXT_DIM)
      gfx.setfont(FONT_BODY); ui_text_c(x + w_side - pol, y, pol, h, "ø")

      -- Output: Limit, Auto, Panel, Out with a peak meter
      x = xr
      ui_button(x, y, w_lim, h, "Limit", LimitOutput ~= 0 and 1 or 0)
      x = x + w_lim + gap
      ui_button(x, y, w_auto, h, ag, AutoGainEnabled ~= 0 and 1 or 0)
      x = x + w_auto + gap
      ui_button(x, y, w_pan, h, "Panel", PanelEnabled ~= 0 and 1 or 0)
      x = x + w_pan + gap

      ui_field(x, y, w_out, h, labels and "OUT" or "", outv, units and "dB" or "", false)
      ui_clip_glow(x, y, w_out, h, ui_clip_out)
      ui_meter(x, y, w_out, h, mw, ui_pk0, ui_pk1)
      gfx.setfont(FONT_BASE)
    end

    -- from ReEQ2 2.2.0: ui_draw_header()
    local function ui_draw_header()
      local s = ui_pt(1)
      if HEADER_H > 0 then
        ui_cola(T.BAR, 1); gfx.rect(0, 0, gfx_w, HEADER_H, 1)
        ui_cola(T.BORDER_SUBTLE, 1); gfx.line(0, HEADER_H, gfx_w, HEADER_H, 0)

        -- Wordmark: Re in white, EQ in bold amber with a superscript 2 (ReEQ squared); then a hairline and a
        -- spaced descriptor when there's room
        local x = 12 * s
        gfx.setfont(FONT_DISPLAY); ui_col(T.WORDMARK_RE)
        ui_text_l(x, 0, HEADER_H, "Re")
        x = x + ui_text_w("Re")
        gfx.setfont(FONT_DISPLAY_B); ui_col(T.WORDMARK_EQ)
        ui_text_l(x, 0, HEADER_H, "EQ")
        x = x + ui_text_w("EQ") + 1 * s
        -- The 2's top at about the capitals' top (the wordmark's line is centred in the header)
        gfx.setfont(FONT_SUP)
        gfx.x = floor(x); gfx.y = floor(HEADER_H * 0.5 - 7.5 * s)
        gfx.drawstr("2")
        x = x + ui_text_w("2")
        if actual_width >= 700 and not compact_height then
          x = x + 10 * s
          ui_col(T.BORDER); gfx.rect(floor(x), floor(HEADER_H * 0.5 - 7 * s), max(1, floor(s)), floor(14 * s), 1)
          x = x + 11 * s
          gfx.setfont(FONT_CAP); ui_col(T.TEXT_DIM)
          local desc = "PARAMETRIC EQUALIZER"
          for i = 1, #desc do
            local ch = desc:sub(i, i)
            ui_text_l(x, 0, HEADER_H, ch)
            x = x + ui_text_w(ch) + 1.4 * s
          end
        end
      end

      -- The top scale label as the dB range button, on its own line
      if not compact_width and not compact_height then
        local ui_dbb_w, ui_dbb_h = 40 * s, 20 * s
        local ui_dbb_x = gfx_w - 4 * s - ui_dbb_w
        local ui_dbb_y = floor(ui_dbb_cy - ui_dbb_h * 0.5)
        gfx.setfont(FONT_BODY)
        if ui_popup == 6 then
          ui_box(ui_dbb_x, ui_dbb_y, ui_dbb_w, ui_dbb_h, 5 * s, T.ACCENT_FILL, 1, T.ACCENT_BORDER)
        else
          ui_box(ui_dbb_x, ui_dbb_y, ui_dbb_w, ui_dbb_h, 5 * s, T.CONTROL, 1, T.BORDER)
        end
        ui_cola(T.DB_LABEL, 1)
        -- 7pt in, so "+30" clears the chevron
        ui_text_l(ui_dbb_x + 7 * s, ui_dbb_y, ui_dbb_h, ui_dbb_lab)
        ui_cola(T.DB_LABEL, 0.7)
        ui_chevron(ui_dbb_x + ui_dbb_w - 10 * s, ui_dbb_y + ui_dbb_h * 0.5, 3 * s, 1)
      end
      gfx.setfont(FONT_BASE)
    end

    -- from ReEQ2 2.1.0: ui_draw_top()
    local function ui_draw_top()
      local h, y = ui_pt(22), ui_pt(6)
      local gw = ui_pt(24)
      local gx = gfx_w - ui_pt(12) - gw
      local lab = Display_Mode == 2 and "Analyzer · Off" or Show_PreEQ ~= 0 and "Analyzer · Pre + Post" or "Analyzer · Post"
      gfx.setfont(FONT_BODY)
      local aw = ui_text_w(lab) + ui_pt(16)
      local ax = gx - ui_pt(8) - aw
      ui_button(ax, y, aw, h, lab, ui_popup == 4 and 1 or 0)
      ui_icon_button(gx, y, gw, h, 5, ui_popup == 5 and 1 or 0)
      gfx.setfont(FONT_BASE)
    end

    -- from ReEQ2 2.1.0: ui_draw_panel() (drawing only)
    local function ui_draw_panel()
      local s = ui_pt(1)
      local b = selected_node
      local t = Band_Type[b]
      local x, y, w, h = panel_x, panel_y, panel_w, panel_h
      local cut = ui_is_cut(t)

      -- Card, see-through so the response shows underneath
      ui_cola(T.PANEL, 1); ui_fill_rrect(x, y, w, h, 8 * s)
      ui_cola(T.BORDER, 1); gfx.roundrect(x, y, w - 1, h - 1, 8 * s, 1)
      ui_cola(T.BORDER_HOVER, 1); gfx.line(x + 8 * s, y, x + w - 8 * s, y, 1)

      -- Header: band badge, shape and placement pickers
      local hy, hh = y + 6 * s, 24 * s
      ui_band_col(b)
      gfx.circle(x + 21 * s, y + 18 * s, 9 * s, 1, 1)
      gfx.setfont(FONT_EMPH); ui_col(T.BADGE_TEXT)
      ui_text_at(x + 21 * s, y + 18 * s, string.format("%d", b + 1))

      local lab = ui_shape_name(t)
      if cut then lab = string.format("%s · %d", ui_shape_name(t), ui_slope_db(ui_slope_index(Band_Slope[b]))) end
      gfx.setfont(FONT_BODY)
      local sw, sx = ui_text_w(lab) + 33 * s, x + 38 * s
      ui_dropdown(sx, hy, sw, hh, lab, ui_popup == 1)

      gfx.setfont(FONT_BODY)
      local gw2 = ui_text_w(ui_group_name(Band_Group[b])) + 33 * s
      local gx2 = sx + sw + 8 * s
      ui_dropdown(gx2, hy, gw2, hh, ui_group_name(Band_Group[b]), ui_popup == 2)

      -- Header: dynamics, for bells and shelves. DYN, then on a dynamic band its detection source, link
      -- and Listen. le is where the left-hand controls end.
      local le = gx2 + gw2
      if band_dyn_capable(t) then
        local dx = gx2 + gw2 + 8 * s
        ui_col(T.BORDER)
        gfx.line(dx, hy + 3 * s, dx, hy + hh - 3 * s, 0)
        dx = dx + 8 * s
        gfx.setfont(FONT_BODY_B); local dw = ui_text_w("DYN") + 18 * s
        ui_button(dx, hy, dw, hh, "DYN", Band_Dyn_On[b] ~= 0 and 1 or 0)
        le = dx + dw
        if Band_Dyn_On[b] ~= 0 and ui_dyn_panel then
          dx = dx + dw + 6 * s
          gfx.setfont(FONT_BODY); dw = ui_text_w("Band") + 33 * s
          ui_dropdown(dx, hy, dw, hh, Band_Dyn_Source[b] == 0 and "Band" or string.format("SC %d", Band_Dyn_Source[b]), ui_popup == 7)
          dx = dx + dw + 6 * s
          ui_icon_button(dx, hy, 26 * s, hh, Band_Dyn_Link[b] ~= 0 and 7 or 8, Band_Dyn_Link[b] ~= 0 and 1 or 0)
          dx = dx + 26 * s + 6 * s
          ui_icon_button(dx, hy, 26 * s, hh, 6, Dyn_Listen == b and 1 or 0)
          le = dx + 26 * s
        end
      end

      -- Header right: band navigation, left out when the left-hand controls would reach the icons
      local rx = x + w - 10 * s
      local hnarrow = le + 8 * s > rx - 220 * s
      if not hnarrow then
        ui_text_button(rx - 22 * s, hy, 22 * s, hh, "›")
        -- k / N: this band's position among the bands in use
        local n, k = 0, 0
        for i = 0, NUM_BANDS - 1 do
          if Band_Enabled[i] ~= BAND_STATE_OFF then
            n = n + 1
            if i <= b then k = k + 1 end
          end
        end
        gfx.setfont(FONT_BODY)
        ui_col(T.TEXT_SECONDARY)
        ui_text_c(rx - 58 * s, hy, 36 * s, hh, string.format("%d / %d", k, n))
        ui_text_button(rx - 80 * s, hy, 22 * s, hh, "‹")
        ui_col(T.BORDER)
        gfx.line(rx - 86 * s, hy + 3 * s, rx - 86 * s, hy + hh - 3 * s, 0)
      end

      -- Header right: solo (listen), bypass, duplicate, delete
      local ib = hnarrow and rx or rx - 92 * s
      ui_icon_button(ib - 26 * s, hy, 26 * s, hh, 4, 2)
      ui_icon_button(ib - 60 * s, hy, 26 * s, hh, 3, 0)
      ui_icon_button(ib - 94 * s, hy, 26 * s, hh, 2, Band_Enabled[b] == BAND_STATE_DISABLED and 1 or 0)
      ui_icon_button(ib - 128 * s, hy, 26 * s, hh, 1, listen_node == b and 1 or 0)

      ui_col(T.BORDER_SUBTLE)
      gfx.line(x + 12 * s, y + 36 * s, x + w - 12 * s, y + 36 * s, 0)

      -- Dials. A dynamic band's dials move left for its dynamics block (327pt from the hairline to the
      -- right edge), closer together in a narrow panel
      local dyn = ui_dyn_panel and Band_Dyn_On[b] ~= 0 and band_dyn_capable(t)
      local hl, sp, cx
      if dyn then
        hl = x + w - 327 * s
        sp = min(max((hl - x - 131 * s) * 0.5, 76 * s), 116 * s)
        cx = hl - 60 * s - sp
      else
        cx = x + w * 0.5; sp = 116 * s
      end
      local cy = y + 91 * s

      -- Frequency
      local f = Band_Frequency[b]
      local val
      if f < 1000 then val = string.format(f < 100 and "%.1f" or "%.0f", f) else val = string.format(f < 10000 and "%.2f" or "%.1f", f / 1000) end
      ui_dial_face(cx - sp, cy, "FREQUENCY", freq_to_per(f, 1.0), false, 0, false, val, f < 1000 and "Hz" or "kHz")

      -- Gain, or slope for the cuts
      if cut then
        local k = ui_slope_index(Band_Slope[b])
        ui_dial_face(cx, cy, "SLOPE", k / 9, false, 10, false, string.format("%d", ui_slope_db(k)), "dB/oct")
      else
        local dimg = ui_gain_inert(t)
        ui_dial_face(cx, cy, "GAIN", (Band_Gain[b] / BAND_GAIN_MAX + 1) * 0.5, true, 0, dimg, ui_fmt_db(Band_Gain[b]), "dB")
      end

      -- Q, or resonance for the cuts
      local dimq = ui_q_inert(b)
      ui_dial_face(cx + sp, cy, cut and "RESONANCE" or "Q", q_to_per(Band_Q[b], 1.0), false, 0, dimq, string.format("%.2f", Band_Q[b]), "")

      if dyn then ui_draw_dyn_block(b, hl, y, x + w) end

      -- The pickers (ui_draw_shape_pop, ui_draw_stereo_pop, ui_draw_dyn_source_pop) would draw here, last
      gfx.setfont(FONT_BASE)
    end

    return ui_draw_header, ui_draw_top, ui_draw_bar, ui_draw_panel
  end)()

  ------------------------------------------------------------------------------------------------
  -- One frame of ReEQ2, into an offscreen image
  ------------------------------------------------------------------------------------------------

  local draw, pick, thumb = (function()
    local IMG, PICK_IMG = 100, 101

    -- from ReEQ2 2.1.0: the @gfx main section, in its order, fully faded in (ui_fade 1)
    local function render(pick)
      picking = pick
      pal_load()
      -- The analyser as the editor's buttons set it; Listen hears band 3 on its own (its solo button), and
      -- Ghost unlinks its detector, which gives it a ghost spectrum
      Display_Mode = an.mode == "fill" and 0 or an.mode == "line" and 1 or an.mode == "heat" and 3 or 2
      Show_PreEQ = an.pre and 1 or 0
      SPEC_MODE = an.second and 3 or 1
      listen_node = an.listen and 2 or -1
      Band_Dyn_Link[2] = an.ghost and 0 or 1
      layout()
      spectrum.top_margin = TOP_MARGIN
      spectrum.bottom_margin = BOTTOM_MARGIN
      spectrum.left_margin = LEFT_MARGIN
      spectrum_colours()

      local dest = gfx.dest
      local img = pick and PICK_IMG or IMG
      gfx.setimgdim(img, gfx_w, gfx_h)
      gfx.dest = img
      gfx.mode = 0
      -- gfx_clear: black
      gfx.set(0, 0, 0, 1)
      gfx.rect(0, 0, gfx_w, gfx_h, 1)

      -- Fonts. Nothing is drawn in the base font: its height (ui_th1, gfx_texth) places the graph.
      gfx.setfont(FONT_BASE, "Arial", floor(rscale(12, 20) + 0.5), BOLD)
      ui_th1 = gfx.texth
      ui_font(FONT_CAP, 10, 0)
      ui_font(FONT_BODY, 12, 0)
      ui_font(FONT_BODY_B, 12, BOLD)
      ui_font(FONT_EMPH, 13, BOLD)
      ui_font(FONT_DISPLAY, 15, 0)
      ui_font(FONT_DISPLAY_B, 15, BOLD)
      ui_font(FONT_NODE, 10.5, BOLD)
      ui_font(FONT_SUP, 9, BOLD)
      gfx.setfont(FONT_BASE)

      update_visual_filters()

      -- Background: a faint vertical gradient over the graph (picks as T_GRAPH_BG above halfway, then
      -- T_GRAPH_BG_LOW)
      local ui_bg_h = max(gfx_h - BOTTOM_MARGIN, 1)
      if picking then
        pick_set(T.GRAPH_BG); gfx.rect(0, 0, gfx_w, floor(ui_bg_h * 0.5), 1)
        pick_set(T.GRAPH_BG_LOW); gfx.rect(0, floor(ui_bg_h * 0.5), gfx_w, ui_bg_h - floor(ui_bg_h * 0.5), 1)
      else
        local p, q = Pal[T.GRAPH_BG], Pal[T.GRAPH_BG_LOW]
        gfx.gradrect(0, 0, gfx_w, ui_bg_h, p[1] / 255, p[2] / 255, p[3] / 255, p[4], 0, 0, 0, 0,
          (q[1] - p[1]) / 255 / ui_bg_h, (q[2] - p[2]) / 255 / ui_bg_h, (q[3] - p[3]) / 255 / ui_bg_h, 0)
      end

      -- The lower shade: in the pick image it goes under the analyser, where it's at least half strength
      local ht = (gfx_h - BOTTOM_MARGIN - gfx.texth) + 2
      if picking then
        pick_set(T.GRAPH_SHADE); gfx.rect(0, floor(ht * 0.75), gfx_w, ht - floor(ht * 0.75), 1)
      end

      -- Set the colors for the bands: fixed per band. (ReEQ2 sets them after the grid, and the ghost
      -- spectrum uses the previous frame's, which are the same.)
      for band = 0, NUM_BANDS - 1 do
        ui_band_col(band)
        Band_Red[band] = gfx.r; Band_Green[band] = gfx.g; Band_Blue[band] = gfx.b
      end

      -- While a band is heard, the listen filter as the previous frame's draw_listen_helper() left it
      if do_listen ~= 0 or listen_node ~= -1 then draw_listen_helper(false) end

      -- The analyser
      if Display_Mode ~= 2 then
        spectrum.draw(0)
        if SPEC_MODE == 3 or SPEC_MODE == 6 then spectrum.draw(1) end
        if Show_PreEQ ~= 0 then
          spectrum.draw(2)
          if SPEC_MODE == 3 or SPEC_MODE == 6 then spectrum.draw(3) end
        end
        if do_listen ~= 0 or listen_node ~= -1 then
          spectrum.draw(4)
          if SPEC_MODE == 3 or SPEC_MODE == 6 then spectrum.draw(5) end
        end
      end

      -- The ghost spectrum follows the selected band, else the band whose detector is heard, while that
      -- band's detector hears a sidechain or is unlinked (no detector node is being dragged here)
      if dyn_ghost_ok(selected_node) then
        Ghost_Band = selected_node
      elseif dyn_ghost_ok(Dyn_Listen) then
        Ghost_Band = Dyn_Listen
      else
        Ghost_Band = -1
      end

      -- The ghost spectrum shows with the rest of the controls, or while its band's detector is heard
      if Ghost_Band >= 0 then
        local ui_fade = 1
        local ui_ghost_a = Dyn_Listen == Ghost_Band and 1 or ui_fade
        if ui_ghost_a > 0.01 then draw_dyn_ghost(Ghost_Band, ui_ghost_a) end
      end

      if not picking then
        local p = Pal[T.GRAPH_SHADE]
        local dst_a = p[4] / ht
        gfx.gradrect(0, ht / 2, gfx_w, ht / 2, p[1] / 255, p[2] / 255, p[3] / 255, 0, 0, 0, 0, 0, 0, 0, 0, dst_a * 2)
      end

      -- Draw the lined grid
      if not very_compact_height and not very_compact_width then draw_grid() end

      draw_filter_bands()

      -- Determine which filter response curves to draw
      local drawMid, drawSide, drawLeft, drawRight = false, false, false, false
      for idx = 0, NUM_BANDS - 1 do
        if Band_Enabled[idx] == BAND_STATE_ENABLED then
          local g = Band_Group[idx]
          if g == 1 then drawMid = true elseif g == 2 then drawSide = true elseif g == 3 then drawLeft = true elseif g == 4 then drawRight = true end
        end
      end
      if drawMid then draw_filter_response(1, T.CURVE_MID) end
      if drawSide then draw_filter_response(2, T.CURVE_SIDE) end
      if drawLeft then draw_filter_response(3, T.CURVE_LEFT) end
      if drawRight then draw_filter_response(4, T.CURVE_RIGHT) end
      draw_filter_response(0, T.CURVE)

      -- Dynamic bands: their static settings while they move
      draw_dyn_static()

      -- The header goes over anything that reaches above the graph
      ui_draw_header()

      -- What shows while the mouse is over the window, fully faded in. The hover card shows for the band
      -- being heard (the mouse is near no node).
      if do_listen ~= 0 or listen_node ~= -1 then draw_listen_helper(true) end
      if not very_compact_height and not very_compact_width then draw_info_panel() end
      draw_dyn_range()
      draw_dyn_detectors()
      draw_nodes()

      if not compact_height and not compact_width then
        ui_draw_bar()
        ui_draw_top()
      end
      if ShowPanel ~= 0 and selected_node ~= -1 then ui_draw_panel() end

      -- Popups draw here, last and over everything (ui_popup 3 node card, 4 analyser, 5 settings, 6 dB
      -- range, 8 credits, 9 value stepper); the preview shows none yet

      gfx.dest = dest
      gfx.mode = 0
      picking = false
    end

    -- Where the image sits in x, y, w, h: as large as fits, keeping its shape, centred
    local function placement(x, y, w, h)
      local k = min(w / gfx_w, h / gfx_h)
      local dw, dh = floor(gfx_w * k), floor(gfx_h * k)
      return x + floor((w - dw) / 2), y + floor((h - dh) / 2), dw, dh, k
    end

    -- What the image shows (the theme version, analyser options and scale it was drawn for), and when
    local drawn, drawn_t = nil, 0

    local function draw(x, y, w, h)
      local sig = string.format("%d %s %s %s %s %s %s", preview_version, an.mode, tostring(an.pre), tostring(an.second),
        tostring(an.listen), tostring(an.ghost), tostring(S))
      -- Drawn again when any of those changed, at most 20 times a second (while a slider is dragged)
      local now = r.time_precise()
      if sig ~= drawn and (not drawn or now - drawn_t >= (mouse.capture and 0.1 or 0.05)) then
        render(false)
        drawn, drawn_t = sig, now
      end
      local dx, dy, dw, dh = placement(x, y, w, h)
      -- Mode 2: the image's own alpha is ignored, it's opaque
      gfx.a = 1
      gfx.mode = 2
      gfx.blit(IMG, 1, 0, 0, 0, gfx_w, gfx_h, dx, dy, dw, dh)
      gfx.mode = 0
    end

    -- The token whose ID colour is at image pixel ix, iy of the pick image (gfx.dest set to it), or nil
    local function pick_at(ix, iy)
      if ix < 0 or iy < 0 or ix >= gfx_w or iy >= gfx_h then return nil end
      gfx.x, gfx.y = ix, iy
      local cr, cg, cb = gfx.getpixel()
      return PICK_KEY[floor(cr * 255 + 0.5) * 65536 + floor(cg * 255 + 0.5) * 256 + floor(cb * 255 + 0.5)]
    end

    -- Surfaces: a click on one looks nearby for something thinner (a line, a label, a node) first, so
    -- 1 px lines such as the analyser's traces are easy to hit
    local SURFACE = {
      graph_bg = true, graph_bg_low = true, graph_shade = true, grid = true, grid_decade = true,
      band_area = true, an_fill = true, an_fill_2 = true, an_heat_low = true, an_heat_high = true, an_heat_2 = true,
      panel = true, popover = true, tile = true, bar = true, control = true,
    }

    local function pick(x, y, w, h)
      if not drawn then return nil end
      render(true)
      local dx, dy, _, _, k = placement(x, y, w, h)
      local ix, iy = floor((mouse.x - dx) / k), floor((mouse.y - dy) / k)
      local dest = gfx.dest
      gfx.dest = PICK_IMG
      local key = pick_at(ix, iy)
      if not key or SURFACE[key] then
        -- The nearest non-surface within about 4 pt; failing that, the token most of the pixels right
        -- around the point have (an antialiased edge)
        local reach = floor(4 * S + 0.5)
        local near, near_d = nil, math.huge
        local count, best, common = {}, 0, nil
        for oy = -reach, reach do
          for ox = -reach, reach do
            local kk = pick_at(ix + ox, iy + oy)
            if kk then
              local d = ox * ox + oy * oy
              if not SURFACE[kk] and d < near_d then near, near_d = kk, d end
              if math.abs(ox) <= 1 and math.abs(oy) <= 1 then
                count[kk] = (count[kk] or 0) + 1
                if count[kk] > best then best, common = count[kk], kk end
              end
            end
          end
        end
        key = near or key or common
      end
      gfx.dest = dest
      return key
    end

    -- Theme t drawn into image img, scaled to tw x th pixels (the gallery's thumbnails). The preview is
    -- drawn again afterwards, with the theme being edited.
    local function thumb(t, img, tw, th)
      local edited = theme.c
      theme.c = t.c
      render(false)
      theme.c = edited
      drawn = nil
      local dest = gfx.dest
      gfx.setimgdim(img, tw, th)
      gfx.dest = img
      gfx.a = 1
      gfx.mode = 2
      gfx.blit(IMG, 1, 0, 0, 0, gfx_w, gfx_h, 0, 0, tw, th)
      gfx.mode = 0
      gfx.dest = dest
    end

    return draw, pick, thumb
  end)()

  return draw, pick, thumb
end

preview_draw, preview_pick, preview_thumb = preview_module()

----------------------------------------------------------------------------------------------------
-- Main window
----------------------------------------------------------------------------------------------------

local function save_current()
  if save_theme(theme, THEME_FILE) then
    saved = { name = theme.name, c = copy_colours(theme.c) }
    say("Saved. Every ReEQ2 uses this theme.")
  else
    say("Couldn't write " .. THEME_FILE .. ".")
  end
end

-- The themes installed with ReEQ2 (by ReaPack, into Themes/): an update replaces them, so a theme saved
-- under one of these names would be lost
local SHIPPED = {}
for _, n in ipairs({ "Amber", "Default", "Espresso", "Fjord", "Forest", "Glacier", "High Contrast", "Matcha",
    "Midnight Neon", "Mono", "Ocean", "Paper", "Phosphor", "Rose", "Rosé", "Sunset", "Synthwave" }) do
  SHIPPED[n:lower()] = true
end

local function save_as()
  local name = theme.name
  if SHIPPED[name:lower()] then name = name .. " (mine)" end
  while true do
    local ok
    ok, name = r.GetUserInputs("Save ReEQ2 theme as", 1, "Theme name,extrawidth=120", name)
    if not ok or trim(name) == "" then return end
    name = trim(name)
    if not SHIPPED[name:lower()] and not SHIPPED[safe_file_name(name):lower()] then break end
    r.ShowMessageBox("\"" .. name .. "\" is one of the themes that come with ReEQ2, and an update would replace it.\n\n" ..
      "Choose another name.", "Save ReEQ2 theme as", 0)
  end
  theme.name = name
  local path = THEMES_DIR .. "/" .. safe_file_name(theme.name) .. ".txt"
  if r.file_exists(path) and r.ShowMessageBox("Replace the theme \"" .. theme.name .. "\"?", "Save ReEQ2 theme as", 4) ~= 6 then return end
  if save_theme(theme, path) then save_current() else say("Couldn't write " .. path .. ".") end
end

local function revert()
  load_into_editor(saved)
  say("Back to the saved theme.")
end

local function top_bar(x, y, w)
  local h = pt(26)
  local title = "ReEQ2 Theme Editor"
  font(14, true)
  local nx = x + gfx.measurestr(title) + pt(14)
  text(title, x, y, nx - x, h, 0, 0xDFE6E9, 14, true)
  local label = theme.name .. (dirty() and "  •" or "")
  if button(label, nx, y, button_w(label), h) then
    local ok, name = r.GetUserInputs("Rename ReEQ2 theme", 1, "Theme name,extrawidth=120", theme.name)
    if ok and trim(name) ~= "" then push_undo(); theme.name = trim(name) end
  end
  local bx = x + w
  local function right(label, on)
    bx = bx - button_w(label)
    local hit = button(label, bx, y, button_w(label), h, on)
    bx = bx - pt(6)
    return hit
  end
  if right("Save", dirty()) then save_current() end
  if right("Save as") then save_as() end
  if right("Revert") then revert() end
  if right("Undo") and #undo > 0 then
    local u = table.remove(undo)
    theme.name, theme.c = u.name, u.c
    whole_reset(); pick_from_token(); push_live(theme)
  end
  if right("Gallery", view == "gallery") then
    if view == "gallery" then view = "main" else gallery = list_themes(); view = "gallery" end
  end
  return h
end

local function analyser_bar(x, y, w)
  local h = pt(24)
  caption("ANALYSER", x, y + pt(7))
  local bx = x + pt(66)
  for _, m in ipairs({ { "off", "Off" }, { "fill", "Fill" }, { "line", "Line" }, { "heat", "Heat" } }) do
    if button(m[2], bx, y, button_w(m[2]), h, an.mode == m[1]) then an.mode = m[1] end
    bx = bx + button_w(m[2]) + pt(4)
  end
  local rx = x + w - button_w("Mid + Side")
  if button("Mid + Side", rx, y, button_w("Mid + Side"), h, an.second) then an.second = not an.second end
  rx = rx - pt(4) - button_w("Pre-EQ")
  if button("Pre-EQ", rx, y, button_w("Pre-EQ"), h, an.pre) then an.pre = not an.pre end
  rx = rx - pt(4) - button_w("Ghost")
  if button("Ghost", rx, y, button_w("Ghost"), h, an.ghost) then an.ghost = not an.ghost end
  rx = rx - pt(4) - button_w("Listen")
  if button("Listen", rx, y, button_w("Listen"), h, an.listen) then an.listen = not an.listen end
  return h
end

local function whole_bar(x, y, w)
  local h = pt(48)
  box(x, y, w, h, 0x121618, 0x232A2E, pt(8))
  local sw = math.floor((w - pt(260) - pt(44)) / 3)
  local function slider(id, label, i, v, lo, hi, fmt)
    local sx = x + pt(12) + (i - 1) * (sw + pt(16))
    caption(label, sx, y + pt(8))
    text(string.format(fmt, v), sx, y + pt(4), sw, pt(14), 2, 0x9AA5AA, 11)
    local nv = hslider(id, sx, y + pt(24), sw, v, lo, hi)
    if nv ~= v then
      if not whole.base then push_undo(); whole.base = copy_colours(theme.c) end
      return nv, true
    end
    return v, false
  end
  local ch1, ch2, ch3
  whole.hue, ch1 = slider("whole_hue", "HUE SHIFT", 1, whole.hue, -180, 180, "%.0f°")
  whole.sat, ch2 = slider("whole_sat", "SATURATION", 2, whole.sat, 0, 200, "%.0f%%")
  whole.bri, ch3 = slider("whole_bri", "BRIGHTNESS", 3, whole.bri, 50, 150, "%.0f%%")
  if ch1 or ch2 or ch3 then whole_apply() end
  local bx = x + w - pt(232)
  caption("BANDS", bx, y + pt(8))
  bx = bx + pt(44)
  for _, k in ipairs({ { "even", "Even" }, { "warm", "Warm" }, { "cool", "Cool" } }) do
    if button(k[2], bx, y + pt(14), button_w(k[2]), pt(24)) then band_harmony(k[1]) end
    bx = bx + button_w(k[2]) + pt(4)
  end
  return h
end

-- Saves the default UI size, and sends it to the open ReEQ2 windows on the default
local function set_ui_size(v)
  if not save_settings(v) then say("Couldn't write " .. SETTINGS_FILE .. "."); return end
  ui_size = v
  r.gmem_attach(GM_NAME)
  r.gmem_write(GM_UI_SIZE, v)
  say(string.format("ReEQ2 windows on the default UI size show at %d%%.", v))
end

local function window_bar(x, y, w)
  caption("WINDOW", x, y + pt(7))
  local cw, ch = chosen_size()
  local label = size.file_w and string.format("%d × %d", size.file_w, size.file_h) or "ReEQ2 not found"
  if button(label, x + pt(58), y, button_w(label), pt(24), view == "size") then
    size.w, size.h, size.msg = size.file_w or DEFAULT_W, size.file_h or DEFAULT_H, nil
    view = view == "size" and "main" or "size"
  end
  local tx = x + pt(66) + button_w(label)
  if cw and size.file_w and (cw ~= size.file_w or ch ~= size.file_h) then
    local again = string.format("Apply %d × %d again", cw, ch)
    text("An update reset the size.", tx, y, pt(150), pt(24), 0, 0xE8875F, 12)
    if button(again, tx + pt(150), y, button_w(again), pt(24)) then
      local ok, why = set_jsfx_size(cw, ch)
      if ok then read_size(); say(string.format("New ReEQ2 windows open at %d × %d.", cw, ch)) else say(why) end
    end
  else
    text("new ReEQ2 windows open at this size", tx, y, pt(300), pt(24), 0, 0x707A7F, 12)
  end

  -- The default UI size for ReEQ2 windows
  local ux = tx + pt(310)
  caption("UI SIZE", ux, y + pt(7))
  local bx = ux + pt(56)
  for _, v in ipairs(UI_SIZES) do
    local lab = tostring(v)
    if button(lab, bx, y, button_w(lab), pt(24), ui_size == v) and ui_size ~= v then set_ui_size(v) end
    bx = bx + button_w(lab) + pt(4)
  end
  -- The version note is right-aligned; in a narrow window the trailing note gives way to it
  local note = "% default UI size for ReEQ2"
  local right = x + w
  if size.version and size.version ~= PREVIEW_FROM then
    local vnote = string.format("Preview from ReEQ2 %s (installed: %s)", PREVIEW_FROM, size.version)
    text(vnote, x, y, w, pt(24), 2, 0x707A7F, 12)
    right = x + w - gfx.measurestr(vnote) - pt(16)
  end
  font(12)
  if bx + pt(4) + gfx.measurestr(note) <= right then
    text(note, bx + pt(4), y, pt(200), pt(24), 0, 0x707A7F, 12)
  end
end

local WIN_W, WIN_H = 1420, 860
local prev_down, prev_rdown = false, false

local function frame()
  S = math.max(gfx.ext_retina or 1, 1)
  -- Buttons count only while this window has focus and the mouse is over it: REAPER reports them
  -- for clicks in other windows too
  local ours = gfx.getchar(65536) & 2 == 2
    and gfx.mouse_x >= 0 and gfx.mouse_y >= 0 and gfx.mouse_x < gfx.w and gfx.mouse_y < gfx.h
  local down = gfx.mouse_cap & 1 == 1 and (ours or mouse.capture ~= nil)
  local rdown = gfx.mouse_cap & 2 == 2 and ours
  mouse.x, mouse.y = gfx.mouse_x, gfx.mouse_y
  mouse.press, mouse.release = down and not prev_down, prev_down and not down
  mouse.rpress = rdown and not prev_rdown
  mouse.wheel = gfx.mouse_wheel / 120
  gfx.mouse_wheel = 0
  prev_down, prev_rdown = down, rdown
  if not down then mouse.capture = nil end

  rgb(0x0D1012)
  gfx.rect(0, 0, gfx.w, gfx.h, 1)

  -- A popover takes the clicks: the view under it draws without them
  local press = mouse.press
  local size_open = view == "size"
  if size_open then mouse.press = false end

  local m = pt(12)
  local x, y, w = m, m, gfx.w - 2 * m
  y = y + top_bar(x, y, w) + pt(10)
  local bottom = gfx.h - m - pt(24)

  if view == "gallery" then
    -- Back to the editor (Esc does the same)
    if button("←  Back", x, y, button_w("←  Back"), pt(26)) then view = "main" end
    caption("THEMES", x + button_w("←  Back") + pt(12), y + pt(9))
    gallery_view(x, y + pt(36), w, bottom - y - pt(46))
  else
    -- Preview on the left, then the picker, then the token lists (full height, scrolling)
    local pw, tw = pt(300), pt(300)
    local lw = w - pw - tw - pt(20)
    local ly = y + analyser_bar(x, y, lw) + pt(6)
    local ph = math.min(math.floor(lw * DEFAULT_H / DEFAULT_W), bottom - pt(68) - ly)
    if preview_draw then
      preview_draw(x, ly, lw, ph)
      if preview_pick and inside(x, ly, lw, ph) and mouse.press and not mouse.capture then
        local key = preview_pick(x, ly, lw, ph)
        if key then select_token(key) end
      end
    else
      box(x, ly, lw, ph, 0x121618, 0x232A2E, pt(8))
    end
    local ph2 = picker(x + lw + pt(10), y, pw)
    box(x + lw + pt(10), y, pw, ph2, nil, 0x232A2E, pt(8))
    token_lists(x + lw + pw + pt(20), y, tw, bottom - pt(10) - y, 1)
    whole_bar(x, ly + ph + pt(10), lw)
  end
  window_bar(x, bottom, w)

  if view == "size" then
    -- The click that opened the popover isn't one of its own (it would close it at once)
    mouse.press = size_open and press
    size_popover(x + pt(58), bottom - pt(260))
  end

  if note and r.time_precise() - note_t < 4 then
    font(13)
    local nw = gfx.measurestr(note) + pt(24)
    box((gfx.w - nw) / 2, gfx.h - pt(80), nw, pt(30), 0x1F2427, 0x2C3438, pt(8))
    text(note, (gfx.w - nw) / 2, gfx.h - pt(80), nw, pt(30), 1, 0xDFE6E9, 13)
  end

  -- The heartbeat that tells ReEQ2 the editor is running, and any change still waiting to go
  r.gmem_write(3, r.time_precise())
  flush_live()

  gfx.update()
  local ch = gfx.getchar()
  if ch == 27 and view ~= "main" then view = "main" end  -- Esc leaves the gallery or the size popover
  if ch == 26 and #undo > 0 then  -- Cmd/Ctrl+Z
    local u = table.remove(undo)
    theme.name, theme.c = u.name, u.c
    whole_reset(); pick_from_token(); push_live(theme)
  end
  if ch >= 0 then
    r.defer(frame)
  else
    r.SetExtState(EXT, "dock", tostring(gfx.dock(-1)), true)
    if dirty() and r.ShowMessageBox("Save your changes to the ReEQ2 theme?", "ReEQ2 Theme Editor", 4) == 6 then
      save_current()
    end
  end
end

-- Open ReEQ2 windows end on the saved theme, whatever happens to the editor
r.atexit(function() send_live(saved) end)

local function main()
  local t = load_theme(THEME_FILE)
  if t then saved = t end
  theme = { name = saved.name, c = copy_colours(saved.c) }
  ui_size = load_settings()
  read_size()
  select_token(TOKENS[1].key)
  push_live(theme)
  gfx.ext_retina = 1
  gfx.init("ReEQ2 Theme Editor", WIN_W, WIN_H, tonumber(r.GetExtState(EXT, "dock")) or 0)
  frame()
end

main()
