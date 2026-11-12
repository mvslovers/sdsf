-- test/tso/purge.lua -- P on the Status panel, on jobs of its own, submitted
-- before the test: ZSPW held waiting, ZSPO with held output on the print queue,
-- ZSPU with output that is not held, ZSPX running (ISFWAIT). It purges what it finds by these names and says what became of
-- each; a name that is not on the list fails nothing.
local function find(t, name)
  local n = 0
  for l in t:text():gmatch("[^\n]+") do
    n = n + 1
    if n > 3 and l:find(name, 1, true) then return n - 3 + 1, l end
  end
end

local function hunt(t, name)
  t:type("TOP"):enter()
  for _ = 1, 40 do
    local tabs, line = find(t, name)
    if tabs then return tabs, line end
    if t:text():find("LINE %d+%-(%d+) %(%1%)") then return nil end
    t:pf(8)
  end
end

local function purge(t, name)
  local tabs, line = hunt(t, name)
  if not tabs then error("not on the list: " .. name) end
  print("purging: " .. line)
  for _ = 1, tabs do t:tab() end
  t:type("P"):enter()
  print((t:text():gmatch("[^\n]+")()))
  t:type("  "):enter()
  for _ = 1, 10 do
    if not hunt(t, name) then return end
    t:enter()
  end
  error("still there after P: " .. name)
end

local function body(t)
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY ALL CLASSES")
  for _, name in ipairs({ "ZSPW", "ZSPO", "ZSPU", "ZSPX" }) do
    local ok, err = pcall(purge, t, name)
    print(name .. " " .. (ok and "gone" or tostring(err)))
  end
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
