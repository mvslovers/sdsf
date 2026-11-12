-- test/tso/i.lua -- I, the input queue, as on IBM's SDSF V1R2: the title, the
-- heading, the waiting jobs; H and NH, classes, wrong parameters. The rows
-- need a held job ZSIN (test/jcl/zsin.jcl, TYPRUN=HOLD); without one the
-- test says so and checks the rest.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

local function zsin(t)
  return t:text():match("\n(    ZSIN     JOB [^\n]*)")
end

local function body(t)
  t:type("I"):enter()
  t:expect("SDSF INPUT QUEUE DISPLAY")
  print(t:text())
  local s = t:screen()
  if s[1]:sub(1, 37) ~= " SDSF INPUT QUEUE DISPLAY ALL CLASSES" or s[1]:sub(57, 60) ~= "LINE" then
    error("the title is not as in IBM's SDSF V1R2: " .. s[1])
  end
  if s[3] ~= " NP JOBNAME TYPE JNUM  PRTY C  POS DEST     RMT NODE SAFF ASYS STAT" then
    error("the heading is not as in IBM's SDSF V1R2: " .. s[3])
  end
  local row = zsin(t)
  if row then
    -- the columns of IBM's SDSF V1R2: JNUM up to 22, PRTY up to 27, NODE in 52
    if not row:find("^    ZSIN     JOB  +%d+ +%d+ A      LOCAL           1           HOLD$") then
      error("the row of ZSIN is not as in IBM's SDSF V1R2: " .. row)
    end
    t:type("I H"):enter()
    if not zsin(t) then error("I H does not show the held ZSIN") end
    t:type("I NH"):enter()
    if zsin(t) then error("I NH shows the held ZSIN") end
    t:type("IB"):enter()
    if zsin(t) then error("IB shows ZSIN of class A") end
    has(t, "SDSF INPUT QUEUE DISPLAY CLASS B")
    t:type("IA"):enter()
    if not zsin(t) then error("IA does not show ZSIN") end
    -- ? on it: its data sets
    local r = 0
    for i, l in ipairs(t:screen()) do if l:find("^    ZSIN ") then r = i end end
    -- the command field, the scroll field, then the NP fields from row 4
    for _ = 1, r - 2 do t:tab() end
    t:type("?"):enter()
    t:expect("SDSF JOB DATA SET DISPLAY")
    t:pf(3)
    t:expect("SDSF INPUT QUEUE DISPLAY")
  else
    print("no held ZSIN on the input queue: submit test/jcl/zsin.jcl for the rows")
  end
  -- as in IBM's SDSF V1R2 the executing TSO users too: I$ shows this one
  t:type("I$"):enter()
  t:expect("SDSF INPUT QUEUE DISPLAY CLASS $")
  if not t:text():find("\n    IBMUSER  TSU  +%d+ +%d+ %$      LOCAL") then
    print(t:text()); error("I$ does not show the test's TSO user")
  end
  t:type("I $"):enter()
  t:expect("PARM INVALID")
  local _, c = t:cursor()
  if c ~= 23 then error("the cursor is not on $: " .. c) end
  t:type("   "):enter()
  t:type("I H X"):enter()
  t:expect("TOO MANY PARMS")
  t:type("I FOO"):enter()
  t:expect("PARM INVALID")
  t:type("  "):enter()
  t:pf(11)
  has(t, " NP JOBNAME TYPE JNUM  PRTY C  POS DEST")
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY")
  t:type("I"):enter()
  t:expect("SDSF INPUT QUEUE DISPLAY")
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
end

return function(t)
  t:logon(); t:clear()
  t:type("ISPF"):enter()
  t:expect("Primary Option Menu")
  t:type("S"):enter()
  t:expect("COMMAND INPUT")
  local ok, err = pcall(body, t)
  if not ok then print(err); print(t:text()); t:pf(3); t:pf(3) end
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
