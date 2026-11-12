-- test/tso/colors.lua -- the colours of the menu and the lists, as in IBM's
-- SDSF V1R2, read with mbt's t:color: options white and their text blue; NP
-- red; a row blue, white when the job is executing; the fields that can be
-- overtyped green, red in a white row. Needs an mbt with t:color; an older
-- one skips the test.
local function want(t, r, c, color, what)
  local got = t:color(r, c)
  if got ~= color then
    print(t:text())
    error(what .. " (row " .. r .. ", column " .. c .. ") is " .. got .. ", not " .. color)
  end
end

-- the first row from 4 on whose text matches pattern
local function row(t, pattern)
  local s = t:screen()
  for r = 4, #s do
    if s[r]:find(pattern) then return r, s[r] end
  end
end

local function body(t)
  want(t, 6, 6, "white", "the option LOG")
  want(t, 6, 18, "blue", "the text of LOG")
  want(t, 4, 3, "white", "the line above the options")
  want(t, 15, 6, "white", "the option TUTOR, the tutorial being complete")
  want(t, 18, 6, "blue", "Use of the help line")
  want(t, 18, 10, "white", "Help of the help line")
  want(t, 18, 15, "blue", "key of the help line")

  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY")
  local r = row(t, "^    ZSIN ")
  if r then
    want(t, r, 2, "red", "NP")
    want(t, r, 5, "blue", "the name of a held job")
    want(t, r, 27, "green", "PRTY of a job not executing")
    want(t, r, 52, "green", "DEST of a job not executing")
  end
  r = row(t, "^    %S+ +TSU ")
  want(t, r, 5, "white", "the name of a TSO user")
  want(t, r, 27, "red", "PRTY of an executing job")

  t:type("I"):enter()
  t:expect("SDSF INPUT QUEUE DISPLAY")
  r = row(t, "^    ZSIN ")
  if r then
    want(t, r, 27, "green", "PRTY on I")
    want(t, r, 29, "green", "C on I")
    want(t, r, 36, "green", "DEST on I")
    want(t, r, 19, "blue", "JNUM on I")
  end

  t:type("H ALL"):enter()
  t:expect("SDSF HELD OUTPUT DISPLAY")
  r = row(t, "^    %S+ +%u%u%u +%d+ +%d+ %d%d%.%d%d%d   (%S) ")
  if r then
    want(t, r, 36, "green", "C on H")
    want(t, r, 48, "green", "DEST on H")
    want(t, r, 39, "blue", "FORM on H")
  end

  t:type("INIT"):enter()
  t:expect("SDSF INITIATOR DISPLAY")
  r = row(t, "^ +%d+ INACTIVE ")
  if r then want(t, r, 19, "green", "CLASSES of an idle initiator") end
  r = row(t, "^ +%d+ ACTIVE ")
  if r then want(t, r, 19, "red", "CLASSES of an active initiator") end

  t:type("PR"):enter()
  t:expect("SDSF PRINTER DISPLAY")
  r = row(t, "^      PRINTER1 ")
  want(t, r, 7, "blue", "a printer that is not active")
  want(t, r, 25, "green", "SFORM")
  want(t, r, 30, "green", "SCLASS")

  t:type("DA"):enter()
  t:expect("SDSF DA ")
  local s = t:screen()
  local seen = false
  for k = 4, #s do
    if s[k]:sub(54, 54):find("%d") and s[k]:sub(45, 47) ~= "OUT" then
      want(t, k, 5, "white", "an address space in storage")
      want(t, k, 54, "red", "PGN")
      seen = true
    elseif s[k]:sub(45, 47) == "OUT" then
      want(t, k, 5, "blue", "an address space swapped out")
    end
  end
  if not seen then print(t:text()); error("DA shows no PGN") end
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
end

return function(t)
  if not t.color then
    print("this mbt has no t:color: skipped")
    return
  end
  t:logon(); t:clear()
  t:type("ISPF"):enter()
  t:expect("Primary Option Menu")
  t:type("S"):enter()
  t:expect("SDSF PRIMARY OPTION MENU")
  local ok, err = pcall(body, t)
  if not ok then print(err); print(t:text()); t:pf(3); t:pf(3); t:pf(3) end
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
