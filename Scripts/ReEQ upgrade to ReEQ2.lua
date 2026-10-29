-- @description ReEQ: upgrade ReEQ to ReEQ2
-- @author Justin Johnson
-- @version 1.0.0
-- @about
--   Moves every ReEQ in the project (track, master and take FX) over to ReEQ2, keeping all its
--   settings. ReEQ2 reads every ReEQ state, so only the effect's path changes. If any tracks are
--   selected you can upgrade just those. One undo point.

local OLD = "ReJJ[/\\]ReEQ[/\\]ReEQ%.jsfx"

-- ReEQ2 must be installed where REAPER will look for it
local function reeq2_installed()
  local base = reaper.GetResourcePath() .. "/Effects/ReJJ/ReEQ2/ReEQ2.jsfx"
  return reaper.file_exists(base)
end

-- Swap the path on JS lines only (quoted or not), keeping the separators REAPER wrote
local function upgrade_chunk(chunk)
  return chunk:gsub("(<JS%s+\"?)ReJJ([/\\])ReEQ([/\\])ReEQ%.jsfx", "%1ReJJ%2ReEQ2%3ReEQ2.jsfx")
end

local function upgrade_track(track)
  local ok, chunk = reaper.GetTrackStateChunk(track, "", false)
  if not ok or not chunk:find(OLD) then return 0 end
  local new, n = upgrade_chunk(chunk)
  if n > 0 then reaper.SetTrackStateChunk(track, new, false) end
  return n
end

local function main()
  if not reeq2_installed() then
    reaper.ShowMessageBox("ReEQ2 isn't installed (Effects/ReJJ/ReEQ2/ReEQ2.jsfx).\n\nInstall it first, then run this again.",
      "ReEQ: upgrade to ReEQ2", 0)
    return
  end

  local tracks = {}
  local nsel = reaper.CountSelectedTracks(0)
  if nsel > 0 then
    local r = reaper.ShowMessageBox(string.format(
      "Upgrade ReEQ only on the %d selected track%s?\n\nYes: selected tracks only\nNo: the whole project",
      nsel, nsel == 1 and "" or "s"), "ReEQ: upgrade to ReEQ2", 3)
    if r == 2 then return end
    if r == 6 then
      for i = 0, nsel - 1 do tracks[#tracks + 1] = reaper.GetSelectedTrack(0, i) end
    end
  end
  if #tracks == 0 then
    tracks[1] = reaper.GetMasterTrack(0)
    for i = 0, reaper.CountTracks(0) - 1 do tracks[#tracks + 1] = reaper.GetTrack(0, i) end
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local count, ntracks = 0, 0
  for _, track in ipairs(tracks) do
    local n = upgrade_track(track)
    if n > 0 then count = count + n; ntracks = ntracks + 1 end
  end
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("ReEQ: upgrade to ReEQ2", -1)

  reaper.ShowMessageBox(count == 0 and "No ReEQ found." or
    string.format("Upgraded %d ReEQ%s on %d track%s to ReEQ2.", count, count == 1 and "" or "s",
      ntracks, ntracks == 1 and "" or "s"), "ReEQ: upgrade to ReEQ2", 0)
end

main()
