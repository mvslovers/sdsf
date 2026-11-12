-- test/tso/outcmd.lua -- commands of the log and the output, as in
-- IBM's SDSF V1R2: LOCATE, COLS and RESET, SET HEX, WHO, RIGHT n, RETRIEVE, and
-- INPUT ON on the Job Data Set panel.
local function home(t)
  for _ = 1, 3 do
    local r, c = t:cursor()
    if r == 2 and c == 21 then return end
    t:tab()
  end
  error("cursor not at the command line")
end

local function cmd(t, s)
  home(t)
  t:type(s .. string.rep(" ", 40 - #s)):enter()
  print(t:screen()[1])
end

local function want(cond, what, t)
  if not cond then print(t:text()); error(what) end
end

local function body(t)
  t:type("LOG"):enter()
  t:expect("SDSF SYSLOG")
  cmd(t, "LOCATE 5")
  want(t:screen()[1]:find("LINE +5  COLUMNS"), "LOCATE 5 is not at line 5", t)
  cmd(t, "L 0")
  want(t:screen()[3]:find("TOP OF DATA", 1, true), "L 0 is not at the top", t)
  cmd(t, "LOCATE ABC")
  want(t:screen()[1]:find("  PARM INVALID$"), "LOCATE ABC is taken", t)
  local _, c = t:cursor()
  want(c == 28, "the cursor is not on ABC: " .. c, t)
  cmd(t, "L 5 6")
  want(t:screen()[1]:find("  TOO MANY PARMS$"), "L 5 6 is taken", t)
  -- the first line with a time: lines of a multi-line message have none
  cmd(t, "LOCATE 00.00.00")
  want(t:screen()[3]:find("^%x%x%x%x %d%d%.%d%d%.%d%d "), "LOCATE 00.00.00 is not at a line with a time", t)
  -- the scale over the data, also after RIGHT 10
  cmd(t, "COLS")
  want(t:screen()[3] == "----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8",
       "COLS is not as in IBM's SDSF V1R2", t)
  cmd(t, "RIGHT 10")
  want(t:screen()[1]:find("COLUMNS  11  90$"), "RIGHT 10 does not move", t)
  want(t:screen()[3]:sub(1, 10) == "----+----2", "the scale does not move", t)
  cmd(t, "LEFT 10")
  cmd(t, "RESET")
  want(not t:screen()[3]:find("----+----1", 1, true), "RESET leaves the scale", t)
  -- hex: the text, the zone and the numeric digits, a line of dashes
  -- (a line with a time: the first line of the trace table changes as it
  -- wraps, and its flags may have letters, so only the time is checked)
  cmd(t, "LOCATE 00.00.00")
  cmd(t, "SET HEX ON")
  local s = t:screen()
  want(s[4]:find("^%x%x%x%x4FF4FF4FF4") and s[5]:find("^%x%x%x%x0") and s[6]:find("^ %-%-%-%-%-"),
       "SET HEX ON is not as in IBM's SDSF V1R2", t)
  cmd(t, "SET HEX OFF")
  -- (a log line may itself begin with FFFF, its routing flags: so the
  -- zone digits of the time and the dashes are looked for)
  s = t:screen()
  want(not s[4]:find("^%x%x%x%x4FF4FF4FF4") and not s[6]:find("^ %-%-%-%-%-"),
       "SET HEX OFF leaves hex", t)
  cmd(t, "SET HEX ?")
  want(t:screen()[1]:find("  PARM INVALID$"), "SET HEX ? is taken", t)
  cmd(t, "WHO")
  want(t:screen()[3]:find("^ USER%-ID=IBMUSER   LOGON%-PROC=%S+ +TERMINAL%-NAME=%S"), "WHO is not as in IBM's SDSF V1R2", t)
  cmd(t, "")
  want(not t:screen()[3]:find("USER-ID", 1, true), "WHO stays", t)
  -- RETRIEVE: the commands taken, newest first; scrolling is not kept
  cmd(t, "DOWN 1")
  cmd(t, "RETRIEVE")
  want(t:screen()[2]:find("===> SET HEX OFF ", 1, true), "RETRIEVE: " .. t:screen()[2], t)
  cmd(t, "RETRIEVE")
  want(t:screen()[2]:find("===> SET HEX ON ", 1, true), "RETRIEVE twice: " .. t:screen()[2], t)
  cmd(t, "")
  -- INPUT ON: the job's input too; JES2's data sets keep their DD names
  local function rows(t)
    local n = 0
    for i, l in ipairs(t:screen()) do if i > 3 and l:find("^    %S") then n = n + 1 end end
    return n
  end
  cmd(t, "INPUT")
  want(t:screen()[1]:find("  TOO FEW PARMS$"), "INPUT alone is taken", t)
  cmd(t, "INPUT ON")
  cmd(t, "ST ZSWA")
  t:expect("SDSF STATUS DISPLAY")
  want(t:screen()[4]:find("^    ZSWA "), "no ZSWA on ST", t)
  t:tab(); t:tab(); t:type("?"):enter()
  t:expect("SDSF JOB DATA SET DISPLAY")
  print(t:text())
  want(t:text():find("JESMSGLG", 1, true), "INPUT ON: no JESMSGLG", t)
  want(not t:text():find("$JES2LOG", 1, true), "INPUT ON: $JES2LOG instead of JESMSGLG", t)
  local on = rows(t)
  t:pf(3)
  t:expect("SDSF STATUS DISPLAY")
  cmd(t, "INPUT OFF")
  t:tab(); t:tab(); t:type("?"):enter()
  t:expect("SDSF JOB DATA SET DISPLAY")
  want(t:text():find("JESMSGLG", 1, true), "INPUT OFF: no JESMSGLG", t)
  want(on > rows(t), "INPUT ON shows no more data sets than OFF", t)
  t:pf(3)
  t:expect("SDSF STATUS DISPLAY")
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
  if not ok then print(err); print(t:text()) end
  for _ = 1, 4 do
    if t:text():find("Primary Option Menu", 1, true) then break end
    pcall(home, t); t:type(string.rep(" ", 40))
    t:pf(3)
  end
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
