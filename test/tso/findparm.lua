-- test/tso/findparm.lua -- the FIND parameters on the log, with the messages
-- as in IBM's SDSF V1R2: WORD, PREFIX, SUFFIX ($ # @ count as letters),
-- ALL with the number of hits, X'..', columns, the refusals; FINDLIM.
local function line1(t) return t:screen()[1] end

local function has1(t, pat)
  if not line1(t):find(pat) then
    print(t:text())
    error("line 1 is not as in IBM's SDSF V1R2: " .. line1(t) .. " (want " .. pat .. ")")
  end
end

-- the command line from its start: after a hit the cursor is on it
local function home(t)
  for _ = 1, 3 do
    local r, c = t:cursor()
    if r == 2 and c == 21 then return end
    t:tab()
  end
  error("cursor not at the command line")
end

local function cmd(t, s)
  home(t)
  t:type(s .. string.rep(" ", 40 - #s)):enter()
  print(line1(t))
end

local function body(t)
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  cmd(t, "TOP")
  cmd(t, "F $HASP373 WORD");          has1(t, "  WORD  '%$HASP373' FOUND$")
  cmd(t, "TOP")
  cmd(t, "F HASP373 SUFFIX");         has1(t, " SUFFIX 'HASP373' FOUND$")
  cmd(t, "TOP")
  cmd(t, "F $HAS PREFIX");            has1(t, " PREFIX '%$HAS' FOUND$")
  cmd(t, "TOP")
  cmd(t, "F $HAS WORD");              has1(t, " NO  WORD  '%$HAS' FOUND$")
  cmd(t, "F $HASP373 ALL");           has1(t, "LINE +[%d,]+ +%d+  CHARS '%$HASP373")
  cmd(t, "TOP")
  cmd(t, "F X'5BC8C1E2D7F3F7F3'");    has1(t, "  CHARS  X'5BC8C1E2D7")
  cmd(t, "TOP")
  -- the message text starts in column 25 of the log
  cmd(t, "F $HASP373 25 40");         has1(t, "  CHARS '%$HASP373' FOUND$")
  cmd(t, "TOP")
  cmd(t, "F $HASP373 24");            has1(t, " NO CHARS  '%$HASP373' FOU")
  cmd(t, "F X'C9C'");                 has1(t, "  INVALID HEX STRING$")
  local _, c = t:cursor()
  if c ~= 23 then error("the cursor is not on the hex string: " .. c) end
  cmd(t, "F $HASP373 500");           has1(t, "  INVALID LEFT BOUNDARY$")
  cmd(t, "F $HASP373 25 26");         has1(t, "  INCONSISTENT PARAMETERS$")
  cmd(t, "F A FIRST ALL");            has1(t, "  INCONSISTENT PARAMETERS$")
  cmd(t, "F A CHARS WORD");           has1(t, "  INCONSISTENT PARAMETERS$")
  cmd(t, "BOTTOM")
  cmd(t, "F $HASP373 PREV")
  cmd(t, "F ZQXZQX PREV");            has1(t, "  %* TOP OF DATA REACHED %*$")
  cmd(t, "FINDLIM");                  has1(t, "  TOO FEW PARMS$")
  cmd(t, "FINDLIM ?")
  if not t:screen()[2]:find("===> FINDLIM 5000 ", 1, true) then
    error("FINDLIM ? does not show 5000: " .. t:screen()[2])
  end
  cmd(t, "FINDLIM 1000")
  cmd(t, "FINDLIM ?")
  if not t:screen()[2]:find("===> FINDLIM 1000 ", 1, true) then
    error("FINDLIM 1000 was not taken: " .. t:screen()[2])
  end
  cmd(t, "FINDLIM 5000")
  cmd(t, "END")
  t:expect("SDSF PRIMARY OPTION MENU")
end

return function(t)
  t:logon(); t:clear()
  t:type("ISPF"):enter()
  t:expect("Primary Option Menu")
  t:type("S"):enter()
  t:expect("COMMAND INPUT")
  local ok, err = pcall(body, t)
  if not ok then print(err); print(t:text()) end
  for _ = 1, 4 do
    if t:text():find("Primary Option Menu", 1, true) then break end
    pcall(home, t); t:type(string.rep(" ", 40))
    t:pf(3)
  end
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
