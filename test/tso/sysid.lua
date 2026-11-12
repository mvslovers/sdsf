-- test/tso/sysid.lua -- SYSID, as in IBM's SDSF V1R2: SYSID ? puts the
-- system on the command line, another system's log is empty (NO SYSLOG
-- FOUND), a name longer than four is invalid, none or two are refused.
local function want(cond, what, t)
  if not cond then print(t:text()); error(what) end
end

local function clear(t)
  t:type(string.rep(" ", 20)):enter()
end

local function body(t)
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  local own = t:screen()[1]:match("SDSF SYSLOG   MTT      (%S+)")
  want(own, "no system in the title: " .. t:screen()[1], t)
  t:type("SYSID ?"):enter()
  want(t:screen()[2]:find("===> SYSID " .. own .. " ", 1, true), "SYSID ?: " .. t:screen()[2], t)
  local _, c = t:cursor()
  want(c == 27, "SYSID ? leaves the cursor at " .. c, t)
  clear(t)
  t:type("SYSID XXXX"):enter()
  want(t:screen()[1]:find("SDSF SYSLOG      0.000 XXXX ", 1, true)
       and t:screen()[1]:find("NO SYSLOG FOUND", 1, true), "SYSID XXXX: " .. t:screen()[1], t)
  t:type("SYSID ABCDEFGHI"):enter()
  want(t:screen()[1]:find("PARM INVALID", 1, true), "nine characters: " .. t:screen()[1], t)
  clear(t)
  t:type("SYSID"):enter()
  want(t:screen()[1]:find("TOO FEW PARMS", 1, true), "SYSID alone: " .. t:screen()[1], t)
  clear(t)
  t:type("SYSID A B"):enter()
  want(t:screen()[1]:find("TOO MANY PARMS", 1, true), "two names: " .. t:screen()[1], t)
  clear(t)
  t:type("SYSID " .. own):enter()
  want(t:screen()[1]:find("SDSF SYSLOG   MTT      " .. own, 1, true)
       and not t:screen()[1]:find("NO SYSLOG", 1, true), "back to " .. own .. ": " .. t:screen()[1], t)
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
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
