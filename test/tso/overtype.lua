-- test/tso/overtype.lua -- fields that can be overtyped, as in
-- IBM's SDSF V1R2: on ST PRTY (from column 23) and DEST, on I also C. A
-- priority goes as $TJnnnn,P=n, a class as $TJnnnn,C=x, a destination as
-- $RALL,J=Jnnnn,D=dest; the title says COMMAND ISSUED and the rows stay
-- until the next refresh. A value refused (FIELD NOT NUMERIC, INVALID
-- DESTINATION NAME) stays in its field with the cursor on it, and nothing
-- goes. Needs the held ZSIN (test/jcl/zsin.jcl); changes its priority
-- and class and puts them back.
local function rowof(t, pat)
  local s = t:screen()
  for r = 4, #s do if s[r]:find(pat) then return r end end
end

local function title_has(t, text)
  if not t:screen()[1]:find(text, 1, true) then
    print(t:text()); error("the title does not say " .. text .. ": " .. t:screen()[1])
  end
end

-- the cursor onto row r, column col: Tab from the command line, checked
local function to_field(t, r, col)
  local cr, cc = t:cursor()
  if cr ~= 2 or cc ~= 21 then error("the cursor is not on the command line: " .. cr .. "," .. cc) end
  for _ = 1, 80 do
    t:tab()
    cr, cc = t:cursor()
    if cr == r and cc == col then return end
    if cr > r then break end
  end
  error("the field at " .. r .. "," .. col .. " not reached")
end

local function logged(t, cmd)
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  t:type("BOTTOM"):enter()
  t:type("FIND '" .. cmd .. "' LAST"):enter()
  if not t:screen()[1]:find("FOU", 1, true) or t:screen()[1]:find("NO ", 1, true) then
    print(t:text()); error("the log does not have " .. cmd)
  end
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
end

local function zsin_row(t)
  local r = rowof(t, "^    ZSIN ")
  if not r then print(t:text()); error("ZSIN is not on the panel") end
  return r, t:screen()[r]
end

-- on row r: the field at col overtyped with text; the title then says msg
local function over(t, r, col, text, msg)
  to_field(t, r, col)
  t:type(text):enter()
  title_has(t, msg)
end

local function body(t)
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY")
  t:type("PRE ZSIN"):enter()
  local r, line = zsin_row(t)
  local num = line:match("^    ZSIN +JOB +(%d+)")
  local prio = line:match("^    ZSIN +JOB +%d+ +(%d+) ")

  -- not a number: refused, kept, the cursor on it
  over(t, r, 24, "   X", "FIELD NOT NUMERIC")
  local cr, cc = t:cursor()
  if cr ~= r or cc ~= 24 or t:screen()[r]:sub(24, 27) ~= "   X" then
    print(t:text()); error("X is not kept in PRTY with the cursor on it: " .. cr .. "," .. cc)
  end
  -- typed over: the command goes, the row stays as it was until Enter
  t:type("   3"):enter()
  title_has(t, "COMMAND ISSUED")
  if not t:screen()[r]:find("^    ZSIN +JOB +%d+ +" .. prio .. " ") then
    print(t:text()); error("the row did not stay as it was")
  end
  t:enter()
  if not t:screen()[r]:find("^    ZSIN +JOB +%d+ +3 ") then
    print(t:text()); error("the priority of ZSIN is not 3")
  end

  -- a destination that is none: refused, nothing goes; the same one
  -- again is no command
  over(t, r, 51, "XYZZY   ", "INVALID DESTINATION NAME")
  cr, cc = t:cursor()
  if cr ~= r or cc ~= 51 then print(t:text()); error("the cursor is not on DEST") end
  t:type("LOCAL   "):enter()
  if t:screen()[1]:find("COMMAND ISSUED", 1, true) then
    print(t:text()); error("the same destination went as a command")
  end
  over(t, r, 24, string.format("%4s", prio), "COMMAND ISSUED")
  t:type("PRE"):enter()
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
  logged(t, "$TJ" .. num .. ",P=3")

  -- I: PRTY and C (on IBM's SDSF V1R2 C is a field of its own; here PRTY and C
  -- share one, Wally ISPF, the values are read apart)
  t:type("I"):enter()
  t:expect("SDSF INPUT QUEUE DISPLAY")
  r = zsin_row(t)
  over(t, r, 24, "   X", "FIELD NOT NUMERIC")
  t:type("   4"):enter()
  title_has(t, "COMMAND ISSUED")
  over(t, r, 24, "   4 B", "COMMAND ISSUED")
  t:enter()
  if not t:screen()[r]:find("^    ZSIN +JOB +%d+ +4 B ") then
    print(t:text()); error("ZSIN is not priority 4, class B on I")
  end
  over(t, r, 24, string.format("%4s A", prio), "COMMAND ISSUED")
  t:enter()
  if not t:screen()[r]:find("^    ZSIN +JOB +%d+ +" .. prio .. " A ") then
    print(t:text()); error("ZSIN is not back to priority " .. prio .. ", class A")
  end
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
  logged(t, "$TJ" .. num .. ",C=B")
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
