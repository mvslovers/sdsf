-- test/tso/o.lua -- O, the output not held, as on IBM's SDSF V1R2: the title,
-- the heading and its pages under PF11, classes.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

local pages = {
  " NP JOBNAME TYPE JNUM  PRTY C FORM FCB  DEST       TOT-REC   PRT-REC DEVICE   ST",
  " NP JOBNAME TATUS SYSID RMT  NODE O-GRP-N  OGI1 OGI2 JP UCS  WTR      FLASH BURS",
}

local function body(t)
  t:type("O"):enter()
  t:expect("SDSF OUTPUT ALL CLASSES")
  print(t:text())
  local s = t:screen()
  if not s[1]:find("^ SDSF OUTPUT ALL CLASSES   ALL FORMS LINES [%d,]+ ") then
    error("the title is not as in IBM's SDSF V1R2: " .. s[1])
  end
  if s[3] ~= pages[1] then error("the heading is not as in IBM's SDSF V1R2: " .. s[3]) end
  t:pf(11)
  if t:screen()[3] ~= pages[2] then error("PF11 is not as in IBM's SDSF V1R2: " .. t:screen()[3]) end
  t:pf(11)
  has(t, "FLASH BURST PRMODE")
  t:pf(10); t:pf(10)
  -- forms: the test system's output has STD1; none has NOFORM
  t:type("O STD1"):enter()
  t:expect("ALL CLASSES   FORM STD1 LINES")
  if not t:text():find("\n    %S+ +%u%u%u +%d+ +%d+ . STD1 ") then
    print(t:text()); error("O STD1 shows no row with forms STD1")
  end
  t:type("O NOFORM"):enter()
  t:expect("FORM NOFORM LINES")
  if t:text():find("\n    %S+ +%u%u%u +%d+ +%d+ . ") then
    print(t:text()); error("O NOFORM shows rows")
  end
  t:type("OZ"):enter()
  t:expect("SDSF OUTPUT CLASS Z")
  t:type("O A B"):enter()
  t:expect("TOO MANY PARMS")
  t:type("    "):enter()
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
