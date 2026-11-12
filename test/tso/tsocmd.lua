-- test/tso/tsocmd.lua -- TSO followed by a command, on every panel, as on
-- IBM's SDSF V1R2: the output in line mode, the panel back after Enter with
-- the command line cleared; TSO alone is refused.
local function back(t, title)
  -- Wally ISPF shows the *** only after an Enter, IBM's SDSF V1R2 ISPF at once
  if not t:text():find("***", 1, true) then t:enter() end
  t:expect("***")
  t:enter()
  t:expect(title)
  if not t:screen()[2]:find("^ COMMAND INPUT ===> +SCROLL") then
    print(t:text()); error("the command line is not cleared: " .. t:screen()[2])
  end
end

local function body(t)
  t:type("TSO TIME"):enter()
  t:expect("TIME-")
  back(t, "SDSF PRIMARY OPTION MENU")
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY")
  t:type("TSO TIME"):enter()
  t:expect("TIME-")
  back(t, "SDSF STATUS DISPLAY")
  t:type("TSO XYZZY"):enter()
  t:expect("COMMAND XYZZY NOT FOUND")
  back(t, "SDSF STATUS DISPLAY")
  t:type("TSO"):enter()
  t:expect("COMMAND PARM IS MISSING")
  if t:screen()[2]:find("TSO", 1, true) then
    print(t:text()); error("TSO alone is not cleared from the line")
  end
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  t:type("TSO TIME"):enter()
  t:expect("TIME-")
  back(t, "SDSF SYSLOG")
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
