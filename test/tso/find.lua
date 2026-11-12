-- test/tso/find.lua -- FIND on the log and on the output of a job: a hit
-- becomes the top line, RFIND (PF5) goes on from it, PREV goes back, FIRST
-- and LAST start at an end, a string that is not there says so, and the end
-- of the data says that it was reached. NEXT and PREV go from one data set
-- of a job to the next.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

local function lines(t)
  local l = {}
  for s in t:text():gmatch("[^\n]*") do l[#l + 1] = s end
  return l
end

-- the first line of data, under the title and the command row
local function first(t)
  for _, s in ipairs(lines(t)) do
    if not s:find("SDSF ", 1, true) and not s:find("COMMAND INPUT", 1, true)
       and s ~= "" then
      return s
    end
  end
  return ""
end

local function number(t, word)
  -- IBM's SDSF V1R2 writes the thousands with commas: 1,005
  local n = t:text():match(word .. "%s+([%d,]+)")
  if n == nil then print(t:text()); error("no " .. word .. " on the screen") end
  return tonumber((n:gsub(",", "")))
end

local function top_has(t, text)
  if not first(t):find(text, 1, true) then
    print(t:text())
    error("the top line does not hold " .. text)
  end
  -- the cursor is on the hit
  local row, col = t:cursor()
  local line = t:screen()[row] or ""
  if line:sub(col, col + #text - 1) ~= text then
    print(t:text())
    error("the cursor is not on " .. text .. " but at " .. row .. "," .. col)
  end
end

-- a command, from wherever the cursor is: after a hit it is in the data,
-- and Tab takes it to the command line
local function cmd(t, s)
  local row = t:cursor()
  if row ~= 2 then t:tab() end
  t:type(s):enter()
end

local function log(t)
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")

  cmd(t, "FIND $HASP373 FIRST")
  print(t:text())
  has(t, "CHARS '$HASP373' FOUND")
  top_has(t, "$HASP373")
  local a = number(t, "LINE")

  t:pf(5)
  has(t, "CHARS '$HASP373' FOUND")
  top_has(t, "$HASP373")
  local b = number(t, "LINE")
  if b <= a then error("RFIND did not go on: " .. a .. " then " .. b) end

  -- RFIND typed does the same as the key (isfkfind)
  cmd(t, "RFIND")
  has(t, "CHARS '$HASP373' FOUND")
  top_has(t, "$HASP373")
  local c = number(t, "LINE")
  if c <= b then error("typed RFIND did not go on: " .. b .. " then " .. c) end
  cmd(t, "FIND $HASP373 PREV")
  if number(t, "LINE") ~= b then error("PREV did not come back to " .. b) end

  cmd(t, "FIND $HASP373 PREV")
  top_has(t, "$HASP373")
  if number(t, "LINE") ~= a then error("PREV did not come back to " .. a) end

  -- a string with a blank in quotes; the hit is on the screen
  cmd(t, "F 'LOGGED ON' FIRST")
  has(t, "CHARS 'LOGGED ON' FOUND")
  top_has(t, "LOGGED ON")

  -- from the last one on there is no more: the end is reached
  cmd(t, "FIND $HASP373 LAST")
  top_has(t, "$HASP373")
  local z = number(t, "LINE")
  t:pf(5)
  -- LAST searches backward, so RFIND goes on backward
  if number(t, "LINE") >= z then error("RFIND after LAST did not go back") end
  cmd(t, "FIND * LAST")
  local last = first(t)
  -- none after the last: as in IBM's SDSF V1R2, screen, cursor and message stay
  cmd(t, "FIND * NEXT")
  has(t, "CHARS '$HASP373' FOUND")
  top_has(t, "$HASP373")
  if first(t) ~= last or number(t, "LINE") ~= z then
    print(t:text()); error("the end of the data moved the screen")
  end

  -- and backward from the first; then another string starts at the
  -- screen, and forward: the PREV of the last one is not kept for it
  cmd(t, "FIND $HASP373 FIRST")
  cmd(t, "FIND * PREV")
  has(t, "CHARS '$HASP373' FOUND")
  if number(t, "LINE") ~= a then error("the top of the data moved the screen") end
  cmd(t, "FIND $HASP395")
  has(t, "CHARS '$HASP395' FOUND")
  local h = number(t, "LINE")
  if h < a then error("the new string went back: " .. h .. " before " .. a) end
  -- the log has many of them: going on from the wrapped search backward
  -- would have given the last one
  cmd(t, "FIND $HASP395 LAST")
  if number(t, "LINE") <= h then error("FIND $HASP395 found the last one") end

  -- as in IBM's SDSF V1R2: from the screen, the end is reached first; the next
  -- search starts at the top and only that one says the string is nowhere
  cmd(t, "FIND ZQXZQX")
  has(t, "*BOTTOM OF DATA REACHED*")
  cmd(t, "FIND")
  has(t, "NO CHARS  'ZQXZQX' FOUND")
  -- as in IBM's SDSF V1R2: the message follows the line number, COLUMNS is gone
  if not t:screen()[1]:find("LINE +[%d,]+ NO CHARS  'ZQXZQX' FOUND$") then
    print(t:text())
    error("the title is not as in IBM's SDSF V1R2: " .. t:screen()[1])
  end

  -- PF5 with something on the command line runs that, as in IBM's SDSF V1R2
  t:type("ABC"); t:pf(5)
  has(t, " INVALID COMMAND")
  has(t, "INPUT ===> ABC")
  cmd(t, "   ")

  -- NEXT on the log does nothing and says nothing, as in IBM's SDSF V1R2
  cmd(t, "NEXT")
  if t:text():find("INVALID", 1, true) then print(t:text()); error("NEXT on the log said something") end
  t:pf(3)
end

local function output(t)
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  while not t:text():find(" PRINT ", 1, true) do t:pf(8) end
  -- Tab to NP of the first job on PRINT: a row has more fields than NP
  -- (PRTY and DEST can be overtyped, as in IBM's SDSF V1R2)
  local s, row = t:screen(), nil
  for r = 4, #s do
    if s[r]:find(" PRINT ", 1, true) then row = r; break end
  end
  for _ = 1, 80 do
    t:tab()
    local cr, cc = t:cursor()
    if cr == row and cc == 2 then break end
  end
  t:type("S"):enter()
  t:expect("SDSF OUTPUT DISPLAY")
  print(t:text())
  local d1 = number(t, "DSID")

  cmd(t, "NEXT")
  print(t:text())
  local d2 = number(t, "DSID")
  if d2 == d1 then error("NEXT stayed in data set " .. d1) end
  -- from the top of the data a search covers all of it: NO CHARS at once,
  -- and again on PF5 (as in IBM's SDSF V1R2)
  cmd(t, "TOP")
  cmd(t, "F FOOBARBAZ")
  has(t, "NO CHARS  'FOOBARBAZ'")
  t:pf(5)
  has(t, "NO CHARS  'FOOBARBAZ'")
  cmd(t, "NEXT")
  cmd(t, "NEXT 0")
  if number(t, "DSID") ~= d2 then error("NEXT 0 left data set " .. d2) end
  cmd(t, "PREV")
  if number(t, "DSID") ~= d1 then error("PREV did not come back to " .. d1) end
  -- P is PREV here; past the ends: the top of the data, the last line
  cmd(t, "NEXT")
  cmd(t, "P")
  if number(t, "DSID") ~= d1 then error("P did not go back to " .. d1) end
  cmd(t, "PREV 9")
  has(t, "TOP OF DATA")
  cmd(t, "NEXT 9")
  if t:text():find("TOP OF DATA", 1, true) then error("NEXT 9 stayed at the top") end
  -- the last line is the top line: the bottom follows right under it
  local s = t:screen()
  if not (s[4] or ""):find("BOTTOM OF DATA", 1, true) then
    print(t:text()); error("NEXT 9 did not bring the last line to the top")
  end
  -- a parameter that is no number: PARM INVALID, the cursor on it
  cmd(t, "NEXT X")
  has(t, "PARM INVALID")
  local r, c = t:cursor()
  if r ~= 2 or (t:screen()[2] or ""):sub(c, c) ~= "X" then
    print(t:text()); error("the cursor is not on the X but at " .. r .. "," .. c)
  end
  t:tab(); t:tab()
  cmd(t, "      ")
  cmd(t, "TOP")

  -- every job log has this line; from the bottom FIRST goes back to it
  cmd(t, "BOTTOM")
  cmd(t, "FIND 'J O B   L O G' FIRST")
  print(t:text())
  -- as in IBM's SDSF V1R2: the message starts in column 57 over the line number,
  -- and what does not fit is cut
  if not t:screen()[1]:find("DSID +%d+ LINE  CHARS 'J O B   L O G' F$") then
    print(t:text()); error("the title is not as in IBM's SDSF V1R2: " .. t:screen()[1])
  end
  top_has(t, "J O B   L O G")

  -- and FIND remembers the string between the panels
  t:pf(3)
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  t:pf(3)
end

local function body(t)
  log(t)
  t:expect("SDSF PRIMARY OPTION MENU")
  output(t)
  t:expect("SDSF PRIMARY OPTION MENU")
end

return function(t)
  t:logon(); t:clear()
  t:type("ISPF"):enter()
  t:expect("Primary Option Menu")
  t:type("S"):enter()
  t:expect("COMMAND INPUT")
  local ok, err = pcall(body, t)
  if not ok then print(err); print(t:text()); t:pf(3); t:pf(3); t:pf(3) end
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
