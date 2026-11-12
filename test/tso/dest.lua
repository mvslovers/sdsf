-- test/tso/dest.lua -- DEST, as in IBM's SDSF V1R2: DEST name limits the
-- lists, DEST ? puts the setting on the command line, a wrong name is
-- refused with the cursor on it, more than four are too many, DEST alone
-- shows all again (and is kept in the profile, so it is reset at the end).
-- On H it goes by the destination of the output.
local function want(cond, what, t)
  if not cond then print(t:text()); error(what) end
end

local function rows(t)
  return tonumber(t:screen()[1]:match("%((%d+)%)")) or -1
end

local function body(t)
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY")
  local all = rows(t)
  t:type("DEST LOCAL"):enter()
  want(rows(t) == all, "DEST LOCAL changes ST: " .. t:screen()[1], t)
  t:type("DEST ?"):enter()
  want(t:screen()[2]:find("===> DEST LOCAL ", 1, true), "DEST ?: " .. t:screen()[2], t)
  local _, c = t:cursor()
  want(c == 26, "DEST ? leaves the cursor at " .. c, t)
  t:type(string.rep(" ", 20)):enter()
  t:type("DEST R7"):enter()
  want(rows(t) == 0, "DEST R7 shows jobs: " .. t:screen()[1], t)
  t:type("DEST XYZZY"):enter()
  want(t:screen()[1]:find("INVALID DESTINATION NAME", 1, true), "DEST XYZZY: " .. t:screen()[1], t)
  _, c = t:cursor()
  want(c == 26, "the cursor is not on XYZZY: " .. c, t)
  t:type(string.rep(" ", 20)):enter()
  t:type("DEST A B C D E"):enter()
  want(t:screen()[1]:find("TOO MANY PARMS", 1, true), "five names: " .. t:screen()[1], t)
  t:type(string.rep(" ", 20)):enter()
  t:type("DEST"):enter()
  want(rows(t) == all, "DEST alone does not show all again: " .. t:screen()[1], t)
  -- H by the destination of the output: IBM's SDSF V1R2 keeps them all with
  -- LOCAL and shows none with a remote no output goes to
  t:pf(3)
  t:type("H ALL"):enter()
  t:expect("SDSF HELD OUTPUT DISPLAY")
  local held = rows(t)
  want(held > 0, "no held output to try DEST on", t)
  t:type("DEST LOCAL"):enter()
  want(rows(t) == held, "DEST LOCAL changes H: " .. t:screen()[1], t)
  t:type("DEST R7"):enter()
  want(rows(t) == 0, "DEST R7 shows held output: " .. t:screen()[1], t)
  t:type("DEST"):enter()
  want(rows(t) == held, "DEST alone does not show all of H again: " .. t:screen()[1], t)
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
  if not ok then
    print(err); print(t:text())
    t:type(string.rep(" ", 20)):enter(); t:type("DEST"):enter()   -- leave no limit behind
    t:pf(3); t:pf(3)
  end
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
