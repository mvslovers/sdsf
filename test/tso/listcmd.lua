-- test/tso/listcmd.lua -- commands on the list panels, as on IBM's SDSF V1R2:
-- FIND puts the row with the string at the top, the cursor in its NP
-- column; ALL counts, PF5 goes on from the cursor's row; LOCATE n puts row n at the top; WHO shows the user's line over
-- the heading for one display.
local function want(cond, what, t)
  if not cond then print(t:text()); error(what) end
end

local function body(t)
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY")
  t:type("F ZSWA"):enter()
  print(t:text())
  local s = t:screen()
  want(s[1]:find(" CHARS 'ZSWA' FOUND", 1, true), "FIND on ST: " .. s[1], t)
  want(s[4]:find("^    ZSWA "), "the row of ZSWA is not at the top", t)
  local r, c = t:cursor()
  want(r == 4 and c == 2, "the cursor is not in NP: " .. r .. "," .. c, t)
  t:enter()                     -- the cursor goes back to the command line
  r, c = t:cursor()
  want(r == 2 and c == 21, "Enter leaves the cursor at " .. r .. "," .. c, t)
  t:type("F ZQXZQX"):enter()
  want(t:screen()[1]:find("NO CHARS  'ZQXZQX' FOUND", 1, true) or
       t:screen()[1]:find("BOTTOM OF DATA REACHED", 1, true), "F ZQXZQX: " .. t:screen()[1], t)
  t:type("        "):enter()
  -- as in IBM's SDSF V1R2: ALL counts and goes to the first; PF5 goes on
  -- from the row the cursor is on; PREV from the top row finds nothing
  t:type("TOP"):enter()
  t:type("F INIT ALL"):enter()
  s = t:screen()
  local n = s[1]:match("(%d+) CHARS 'INIT' FOUND")
  want(n and tonumber(n) >= 2, "F INIT ALL does not count: " .. s[1], t)
  local first = s[4]
  want(first:find("^    INIT "), "F INIT ALL is not at an INIT row: " .. first, t)
  t:pf(5)
  s = t:screen()
  want(s[1]:find(" CHARS 'INIT' FOUND", 1, true) and s[4]:find("^    INIT ")
       and s[4] ~= first, "PF5 does not go to the next INIT: " .. s[4], t)
  t:enter()
  t:type("TOP"):enter()
  t:type("F INIT PREV"):enter()
  want(t:screen()[1]:find("* TOP OF DATA REACHED *", 1, true), "F INIT PREV at the top: " .. t:screen()[1], t)
  t:type("           "):enter()
  t:type("TOP"):enter()
  t:type("LOCATE 2"):enter()
  want(t:screen()[1]:find("LINE 2-", 1, true), "LOCATE 2 on ST: " .. t:screen()[1], t)
  t:type("L ABC"):enter()
  want(t:screen()[1]:find("PARM INVALID", 1, true), "L ABC on ST is taken", t)
  t:type("     "):enter()
  t:type("WHO"):enter()
  want(t:screen()[3]:find("^ USER%-ID=IBMUSER "), "WHO on ST: " .. t:screen()[3], t)
  t:enter()
  want(t:screen()[3]:find("^ NP JOBNAME"), "WHO stays on ST", t)
  t:type("INIT"):enter()
  t:expect("SDSF INITIATOR DISPLAY")
  t:type("LOCATE 2"):enter()
  want(t:screen()[4]:find("^ +2 "), "LOCATE 2 on INIT: " .. t:screen()[4], t)
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
  if not ok then print(err); print(t:text()) end
  for _ = 1, 4 do
    if t:text():find("Primary Option Menu", 1, true) then break end
    t:enter()
    t:type(string.rep(" ", 40)); t:pf(3)
  end
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
