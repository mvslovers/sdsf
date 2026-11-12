-- test/tso/st.lua -- the Status panel: the list comes from JES2 and shows
-- this session, it scrolls, a command from the menu works on it, MAX in the
-- scroll field does nothing, and END goes back to the menu.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

local function first_job(t)
  local n = 0
  for l in t:text():gmatch("[^\n]+") do
    n = n + 1
    if n == 4 then return l end
  end
end

local function body(t)
  t:tab(); t:type("PAGE"):enter()
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES", 30)
  print(t:text())
  has(t, "JOBNAME")
  has(t, "IBMUSER  TSU")
  has(t, "EXECUTION")
  has(t, "LINE 1-")

  -- PF8 moves on, MAX in the field moves nothing and leaves the amount
  local top = first_job(t)
  t:pf(8)
  print(t:text())
  if first_job(t) == top then error("PF8 did not scroll") end
  local second = first_job(t)
  t:tab(); t:type("MAX "):pf(8)
  has(t, "SCROLL ===> PAGE")
  if first_job(t) ~= second then error("MAX scrolled") end
  t:pf(7)
  if first_job(t) ~= top then error("PF7 did not come back") end

  -- ? : the further columns of the JCT, PF11 over them in three pages,
  -- the headings as in IBM's SDSF V1R2; ? back. The same on I, 6 to the left
  local function heading(want, what)
    local got = t:screen()[3]:gsub("%s+$", "")
    if got ~= want then print(t:text()); error(what .. " is not as in IBM's SDSF V1R2: " .. got) end
  end
  t:type("?"):enter()
  heading(" NP JOBNAME TYPE JNUM  PRTY QUEUE      C  POS HDN DEST     SAFF ASYS STAT RNUM P", "? on ST")
  t:pf(11)
  heading(" NP JOBNAME PROGRAMMER-NAME      ACCT NOTIFY  ISYS RD-TIME RD-DATE ESYS ST-TIME", "? and PF11 on ST")
  local me = t:text():match("\n    IBMUSER  [^\n]*")
  if not me or not me:find("^\n    IBMUSER  .- %S%S%S%S +%d+:%d%d:%d%d %d%d%.%d%d%d %S+ +%d+:%d%d:%d%d") then
    print(t:text()); error("no reader and start time for the TSO user: " .. tostring(me))
  end
  t:pf(11)
  heading(" NP JOBNAME OTIFY  ISYS RD-TIME RD-DATE ESYS ST-TIME ST-DATE CARDS MC TOT-LINES", "? and PF11 twice on ST")
  t:pf(11)
  heading(" NP JOBNAME OTIFY  ISYS RD-TIME RD-DATE ESYS ST-TIME ST-DATE CARDS MC TOT-LINES", "a third PF11 on ST")
  t:pf(10); t:pf(10)
  t:type("?"):enter()
  heading(" NP JOBNAME TYPE JNUM  PRTY QUEUE      C  POS HDN DEST     SAFF ASYS STAT", "? twice on ST")
  t:type("I"):enter()
  t:expect("SDSF INPUT QUEUE DISPLAY")
  t:type("?"):enter()
  heading(" NP JOBNAME TYPE JNUM  PRTY C  POS DEST     RMT NODE SAFF ASYS STAT RNUM PROGRAM", "? on I")
  t:pf(11)
  heading(" NP JOBNAME MMER-NAME      ACCT NOTIFY  ISYS RD-TIME RD-DATE ESYS ST-TIME ST-DAT", "? and PF11 on I")
  t:pf(11)
  heading(" NP JOBNAME OTIFY  ISYS RD-TIME RD-DATE ESYS ST-TIME ST-DATE CARDS MC TOT-LINES", "? and PF11 twice on I")
  t:type("?"):enter()
  heading(" NP JOBNAME TYPE JNUM  PRTY C  POS DEST     RMT NODE SAFF ASYS STAT", "? twice on I")
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")

  -- commands
  t:type("BOTTOM"):enter()
  print(t:text())
  t:type("TOP"):enter()
  if first_job(t) ~= top then error("TOP") end
  t:type("TUTOR"):enter()
  t:expect("TUTORIAL: SDSF")
  t:pf(3)
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  t:type("XX"):enter()
  t:expect("INVALID COMMAND")
  t:type("  "):enter()
  t:tab(); t:type("FOO "):enter()
  t:expect("INVALID SCROLL AMOUNT")
  t:type("PAGE"):enter()
  has(t, "LINE 1-")

  -- an action that is none is refused and stays in NP (C, P and the
  -- others are real actions now: never type them here)
  t:tab(); t:tab(); t:type("Q"):enter()
  t:expect("INVALID COMMAND")
  if t:screen()[4]:sub(2, 2) ~= "Q" then print(t:text()); error("Q is not kept in NP") end
  t:type(" "):enter()

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
  if not ok then
    print(err); print(t:text())
    t:pf(3); t:pf(3)    -- from a panel under the list as well
  end
  -- out of the panels whatever happened: a session left in ISPF stays logged on
  if not ok then t:pf(3) end
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
