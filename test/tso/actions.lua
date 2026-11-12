-- test/tso/actions.lua -- action characters that go to JES2 as commands,
-- as in IBM's SDSF V1R2: on PR D, S and P issue $DU,PRTn, $SPRTn and
-- $PPRTn; on DA D and L issue $DJnnnn and $LJnnnn (IBM's SDSF V1R2: $LJnnnn,ALL,
-- which JES2 4.1 refuses); on INIT D issues $DIn. The title says
-- COMMAND ISSUED; an action that is none stays in NP with INVALID COMMAND
-- and the cursor on it. Starts and stops PRINTER3 of the test system (drained, it is
-- drained again at the end) and needs ZSWA waiting (mbt/init.lua).
local function rowof(t, pat)
  local s = t:screen()
  for r = 4, #s do if s[r]:find(pat) then return r end end
end

-- the cursor into NP of row r: Tab from the command line, checked
local function to_np(t, r)
  local cr, cc = t:cursor()
  if cr ~= 2 or cc ~= 21 then error("the cursor is not on the command line: " .. cr .. "," .. cc) end
  for _ = 1, 60 do
    t:tab()
    cr, cc = t:cursor()
    if cr == r and cc == 2 then return end
    if cr > r then break end
  end
  error("NP of row " .. r .. " not reached")
end

local function action(t, pat, a)
  local r = rowof(t, pat)
  if not r then print(t:text()); error("no row " .. pat) end
  to_np(t, r)
  t:type(a):enter()
  return r
end

local function title_has(t, text)
  if not t:screen()[1]:find(text, 1, true) then
    print(t:text()); error("the title does not say " .. text .. ": " .. t:screen()[1])
  end
end

-- the log has the command
local function logged(t, cmd)
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  t:type("BOTTOM"):enter()
  t:type("FIND '" .. cmd .. "' LAST"):enter()
  -- a long string cuts the message to FOU
  if not t:screen()[1]:find("FOU", 1, true) or t:screen()[1]:find("NO ", 1, true) then
    print(t:text()); error("the log does not have " .. cmd)
  end
  -- FIND leaves the cursor in the data: back to the menu
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
end

local function body(t)
  t:type("PR"):enter()
  t:expect("SDSF PRINTER DISPLAY")
  action(t, "^      PRINTER3 ", "D")
  title_has(t, "COMMAND ISSUED")
  action(t, "^      PRINTER3 ", "S")
  title_has(t, "COMMAND ISSUED")
  action(t, "^      PRINTER3 ", "P")
  title_has(t, "COMMAND ISSUED")
  -- an action that is none stays where it was typed
  local r = action(t, "^      PRINTER3 ", "X")
  title_has(t, "INVALID COMMAND")
  local cr, cc = t:cursor()
  if cr ~= r or cc ~= 2 or t:screen()[r]:sub(2, 2) ~= "X" then
    print(t:text()); error("X is not kept in NP with the cursor on it: " .. cr .. "," .. cc)
  end
  t:type(" "):enter()
  logged(t, "$DU,PRT3")
  logged(t, "$SPRT3")
  logged(t, "$PPRT3")

  t:type("DA"):enter()
  t:expect("SDSF DA")
  r = rowof(t, "^    ZSWA ")
  if not r then print(t:text()); error("ZSWA is not on DA") end
  local num = t:screen()[r]:sub(38, 42):match("%d+")
  action(t, "^    ZSWA ", "D")
  title_has(t, "COMMAND ISSUED")
  action(t, "^    ZSWA ", "L")
  title_has(t, "COMMAND ISSUED")
  r = action(t, "^    ZSWA ", "Q")
  title_has(t, "INVALID COMMAND")
  if t:screen()[r]:sub(2, 2) ~= "Q" then print(t:text()); error("Q is not kept in NP") end
  t:type(" "):enter()
  logged(t, "$DJ" .. num)
  logged(t, "$LJ" .. num)

  -- ST: D and L as on DA (as in IBM's SDSF V1R2: $DJnnnn, $LJnnnn,ALL)
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY")
  t:type("F ZSWA"):enter()
  t:enter()
  action(t, "^    ZSWA ", "D")
  title_has(t, "COMMAND ISSUED")
  action(t, "^    ZSWA ", "L")
  title_has(t, "COMMAND ISSUED")
  r = action(t, "^    ZSWA ", "Q")
  title_has(t, "INVALID COMMAND")
  t:type(" "):enter()
  logged(t, "$DJ" .. num)

  -- INIT: D as in IBM's SDSF V1R2 ($DIn); P, S, Z are not tried here
  t:type("INIT"):enter()
  t:expect("SDSF INITIATOR DISPLAY")
  action(t, "^ +2 ", "D")
  title_has(t, "COMMAND ISSUED")
  r = action(t, "^ +2 ", "X")
  title_has(t, "INVALID COMMAND")
  if t:screen()[r]:sub(2, 2) ~= "X" then print(t:text()); error("X is not kept in NP on INIT") end
  t:type(" "):enter()
  logged(t, "$DI2")
end

return function(t)
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
