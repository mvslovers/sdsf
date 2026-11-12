-- test/tso/menu.lua -- SDSF from the ISPF primary option menu: S reaches
-- the menu, a known command is answered, an unknown one (also a word of
-- more than eight characters) and a bad scroll
-- amount are refused, the End key returns to ISPF, and the scroll amount
-- is back on the next logon. Needs ISFISP in ISPLLIB, ISFMENU in ISPPLIB
-- and the S entry in the primary option menu.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

local function enter_sdsf(t)
  t:logon(); t:clear()
  t:type("ISPF"):enter()
  t:expect("Primary Option Menu")
  t:type("S"):enter()
  t:expect("COMMAND INPUT")
end

local function leave_sdsf(t)
  t:pf(3)
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
end

return function(t)
  enter_sdsf(t)
  print(t:text())
  t:type("TUTOR"):enter()
  t:expect("TUTORIAL: SDSF")
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
  -- a word of a panel and its classes, as in IBM's SDSF V1R2: eight
  -- characters are H with seven classes, nine are no command
  t:type("HABCDEFG"):enter()
  t:expect("SDSF HELD OUTPUT DISPLAY CLASS ABCDEFG")
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
  t:type("IABCDEFGH"):enter()
  t:expect("INVALID COMMAND")
  has(t, "===> IABCDEFGH")
  t:type(string.rep(" ", 9))
  t:type("XX"):enter()
  t:expect("INVALID COMMAND")
  has(t, "===> XX")
  -- the command is still there: clear it, then a bad amount
  t:type("  ")
  t:tab(); t:type("ABCD"):enter()
  t:expect("INVALID SCROLL AMOUNT")
  print(t:text())
  local r, c = t:cursor()
  print("cursor row " .. r .. " column " .. c)
  -- the cursor must stand on the field: type there without a tab
  t:type("HALF"):enter()
  t:expect("COMMAND INPUT")
  has(t, "SCROLL ===> HALF")
  if t:text():find("INVALID", 1, true) then error("still refused") end
  -- MAX raises no message and the last amount comes back
  t:tab(); t:type("MAX "):enter()
  t:expect("COMMAND INPUT")
  has(t, "SCROLL ===> HALF")
  if t:text():find("INVALID", 1, true) then error("MAX refused") end
  -- a number, then leaving by the End key saves it too
  t:tab(); t:type("25  ")
  leave_sdsf(t)

  enter_sdsf(t)
  print(t:text())
  has(t, "SCROLL ===> 25")
  t:tab(); t:type("PAGE"):enter()
  t:expect("COMMAND INPUT")
  -- MAX is not kept, also when the End key leaves with it in the field
  t:tab(); t:type("MAX ")
  leave_sdsf(t)

  enter_sdsf(t)
  has(t, "SCROLL ===> PAGE")
  leave_sdsf(t)
end
