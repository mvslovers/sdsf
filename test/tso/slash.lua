-- test/tso/slash.lua -- / sends the rest of the command line to the system
-- as an operator command, from the menu, the Status panel and the log; on
-- the log the answer comes into view. A / alone says there is nothing.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

local function body(t)
  t:type("/D T"):enter()
  has(t, "COMMAND ISSUED")
  t:type("/"):enter()
  has(t, "NO COMMAND PROVIDED")
  t:type(" "):enter()

  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  t:type("/D T"):enter()
  has(t, "COMMAND ISSUED")

  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  t:type("/D T"):enter()
  has(t, "COMMAND ISSUED")
  -- the answer of D T, at the end of the log
  for _ = 1, 5 do
    if t:text():find("IEE136I", 1, true) then break end
    t:enter()
  end
  print(t:text())
  has(t, "IEE136I")
  -- a / alone on a list: the / stays and the cursor stands after it, as on
  -- IBM's SDSF V1R2; back to the start of the line before typing over it, or the
  -- next command would go out as an operator command
  t:type("/"):enter()
  has(t, "NO COMMAND PROVIDED")
  local r, c = t:cursor()
  if c ~= 22 then error("the cursor is not after the / but at " .. r .. "," .. c) end
  t:tab(); t:tab()
  t:type(" "):enter()
  if t:text():find("INPUT ===> /", 1, true) then error("the / stayed") end
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
