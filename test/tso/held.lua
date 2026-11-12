-- test/tso/held.lua -- H, the held output, as on IBM's SDSF V1R2: the title
-- with the lines, the heading and its four pages under PF11, H ALL, the
-- user's own jobs without it, S on a row. Held output is what the test
-- system keeps of earlier test sessions (the TSO user's log, class Y on
-- the test system); without any the test says so.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

-- the headings of the pages, as in IBM's SDSF V1R2
local pages = {
  " NP JOBNAME TYPE JNUM  DN  CRDATE  C FORM FCB  DEST      RMT NODE   TOT-REC RNUM",
  " NP JOBNAME   PROGRAMMER-NAME      ACCT NOTIFY  ISYS RD-TIME RD-DATE ESYS ST-TIM",
  " NP JOBNAME ME ST-DATE END-TIME END-DATE CARDS PR STATUS UCS JC BURST PRMODE   W",
  " NP JOBNAME TIME END-DATE CARDS PR STATUS UCS JC BURST PRMODE   WTR     MC FLASH",
}

local function lines(t)
  local s = t:screen()[1]
  local n = s:match("^ SDSF HELD OUTPUT DISPLAY ALL CLASSES +([%d,]+) LINES")
  if not n or s:sub(49, 49) == " " then error("the title is not as in IBM's SDSF V1R2: " .. s) end
  return n
end

local function body(t)
  t:type("H ALL"):enter()
  t:expect("SDSF HELD OUTPUT DISPLAY")
  print(t:text())
  lines(t)
  local s = t:screen()
  if s[3] ~= pages[1] then error("the heading is not as in IBM's SDSF V1R2: " .. s[3]) end
  for k = 2, 5 do
    t:pf(11)
    local want = pages[k > 4 and 4 or k]
    if t:screen()[3] ~= want then
      print(t:text())
      error("PF11 page " .. (k - 1) .. " is not as in IBM's SDSF V1R2: " .. t:screen()[3])
    end
  end
  t:pf(10); t:pf(10); t:pf(10)
  if t:screen()[3] ~= pages[1] then error("PF10 does not go back: " .. t:screen()[3]) end
  local row = s[4]
  if row:find("^    %S") then
    -- DN up to 25, CRDATE from 27, the class in 36, NODE 1 in 65
    if not row:find("^    %S+ +%u%u%u  +%d+ +%d+ %d%d%.%d%d%d   . ") or row:sub(65, 65) ~= "1" then
      error("the row is not as in IBM's SDSF V1R2: " .. row)
    end
    -- S on the first row: its output
    t:tab(); t:tab(); t:type("S"):enter()
    t:expect("SDSF OUTPUT DISPLAY")
    t:pf(3)
    t:expect("SDSF HELD OUTPUT DISPLAY")
  else
    print("no held output on this system")
  end
  -- without ALL only the jobs whose name starts with the user id
  t:type("H"):enter()
  for i, l in ipairs(t:screen()) do
    if i > 3 and l:find("^    %S") and not l:find("^    IBMUSER") then
      error("H shows a job of another user: " .. l)
    end
  end
  -- PREFIX takes the place of the user id rule (as in IBM's SDSF V1R2):
  -- a job of another name on H ALL shows on plain H under PREFIX name
  t:type("H ALL"):enter()
  local other
  for i, l in ipairs(t:screen()) do
    local n = l:match("^    (%S+)")
    if i > 3 and n and n:sub(1, #t.user) ~= t.user then other = n; break end
  end
  if other then
    t:type("PREFIX " .. other):enter()
    t:type("H"):enter()
    local seen = false
    for i, l in ipairs(t:screen()) do
      if i > 3 and l:find("^    " .. other .. " ") then seen = true end
    end
    t:type("PREFIX"):enter()
    if not seen then print(t:text()); error("H under PREFIX " .. other .. " does not show it") end
  else
    print("no held output of another name: PREFIX on H not tried")
  end
  t:type("H ALL X"):enter()
  t:expect("TOO MANY PARMS")
  t:type("  "):enter()
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
