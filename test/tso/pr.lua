-- test/tso/pr.lua -- PR, the printers, as on IBM's SDSF V1R2: from the answer
-- of JES2 to $DU,PRTS; the title, the heading and its four pages, PR with
-- printer numbers.
local function has(t, text)
  if not t:text():find(text, 1, true) then
    print(t:text())
    error("not on the screen: " .. text)
  end
end

local pages = {
  " NP   PRINTER  STATUS  SFORM SCLASS          JOBNAME TYPE JNUM  REC-CNT REC-PRT",
  " NP   PRINTER  JP DP  C FORM FCB  UCS  WRITER  FLASH DEST-NAME BURST SEP SEPDS P",
  " NP   PRINTER PRMODE   SFCB SUCS SWRITER  SFLH WORK-SELECTION",
  " NP   PRINTER          SBURST SPRMODE1 SPRMODE2 SDEST1   SDEST2   SDEST3   SDEST",
  " NP   PRINTER T4   SJOBNAME M   NPRO MODE CKPTLINE CKPTPAGE CKPTSEC CKPTMODE CPY",
}

local function body(t)
  t:type("PR"):enter()
  t:expect("SDSF PRINTER DISPLAY")
  print(t:text())
  local s = t:screen()
  if s[1]:sub(1, 21) ~= " SDSF PRINTER DISPLAY" or s[1]:sub(57, 60) ~= "LINE" then
    error("the title is not as in IBM's SDSF V1R2: " .. s[1])
  end
  if s[3] ~= pages[1] then error("the heading is not as in IBM's SDSF V1R2: " .. s[3]) end
  if not s[4]:find("^      PRINTER1 %u+ +%S+ +%S+") then
    error("PRINTER1 is not the first row: " .. s[4])
  end
  for k = 2, 5 do
    t:pf(11)
    if t:screen()[3]:gsub("%s+$", "") ~= pages[k] then
      print(t:text())
      error("PF11 page " .. (k - 1) .. " is not as in IBM's SDSF V1R2: " .. t:screen()[3])
    end
  end
  t:pf(10); t:pf(10); t:pf(10); t:pf(10)
  t:type("PR 2"):enter()
  t:expect("SDSF PRINTER DISPLAY")
  s = t:screen()
  if not s[4]:find("^      PRINTER2 ") or s[5]:find("PRINTER") then
    error("PR 2 does not show PRINTER2 alone: " .. s[4] .. " / " .. s[5])
  end
  t:type("PR 1-2"):enter()
  has(t, "PRINTER1")
  has(t, "PRINTER2")
  t:type("PR 2-1"):enter()
  t:expect("PARM INVALID")
  t:type("      "):enter()
  t:type("PR X"):enter()
  t:expect("PARM INVALID")
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
