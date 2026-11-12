-- test/tso/log.lua -- LOG shows the master trace table from its end, scrolls,
-- reads again on Enter, reaches ST and back, and END goes to the menu.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

local function body(t)
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  print(t:text())
  -- the columns of the title are those of IBM's SDSF V1R2: the system in 25, the
  -- line number up to 55, two blanks before COLUMNS
  local head = t:screen()[1]
  if head:sub(1, 24) ~= " SDSF SYSLOG   MTT      " or head:sub(25, 25) == " "
     or not head:sub(48, 64):find("^ *[%d,]+  COLUMNS$") then
    error("the title is not as in IBM's SDSF V1R2: " .. head)
  end
  has(t, "BOTTOM OF DATA")
  t:pf(7)
  print(t:text())
  t:type("TOP"):enter()
  print(t:text())
  has(t, "TOP OF DATA")
  t:type("BOTTOM"):enter()
  has(t, "BOTTOM OF DATA")
  t:enter()
  has(t, "BOTTOM OF DATA")
  t:pf(8)
  has(t, "BOTTOM OF DATA")
  t:pf(11)
  has(t, "COLUMNS  81 160")
  t:pf(10)
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
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
