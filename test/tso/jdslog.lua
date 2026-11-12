-- test/tso/jdslog.lua -- ? on the SYSLOG task lists its data set: libc370
-- gives it no SYSOUT flag (libc370#781), and output is everything that is
-- not input.
local function body(t)
  t:type("ST SYSLOG"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  local row = t:screen()[4] or ""
  if not row:find("^    SYSLOG   STC") then print(t:text()); error("row 4 is not SYSLOG: " .. row) end
  t:tab(); t:tab(); t:type("?"):enter()
  t:expect("JOB DATA SET DISPLAY")
  print(t:text())
  if t:text():find("LINE 0-0 (0)", 1, true) then error("no data set for SYSLOG") end
  if not t:text():find("\n    JES%d%d%d%d%d ") then error("no JESnnnnn data set for SYSLOG") end
  t:pf(3)
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
  if not ok then print(err); print(t:text()); t:pf(3); t:pf(3); t:pf(3) end
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
