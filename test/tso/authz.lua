-- test/tso/authz.lua -- what a user without rights sees (no SDSF.OPER, no
-- JESSPOOL profile for other users' jobs): only the own jobs on ST, I, O,
-- H and DA, LOG, PR,
-- INIT refused, / refused, on DA only the own address spaces. Runs only
-- for such a user (a target whose TN3270 user is not IBMUSER), e.g.
--   MBT_TARGET_TN3270_USER=HERC02 ... mbt test --tso --target env --only authz
local function want(cond, what, t)
  if not cond then print(t:text()); error(what) end
end

local function title_after(t, cmd, text)
  t:type(cmd):enter()
  want(t:screen()[1]:find(text, 1, true), cmd .. ": " .. t:screen()[1], t)
  t:type(string.rep(" ", 12)):enter()
end

local function body(t)
  local me = t.user
  title_after(t, "LOG", "COMMAND NOT AUTHORIZED")
  title_after(t, "PR", "COMMAND NOT AUTHORIZED")
  title_after(t, "INIT", "COMMAND NOT AUTHORIZED")
  t:type("ST"):enter()
  t:expect("SDSF STATUS DISPLAY")
  print(t:text())
  local s = t:screen()
  for i = 4, #s do
    local name = s[i]:match("^    (%S+)")
    want(not name or name:sub(1, #me) == me, "ST shows a job of another user: " .. s[i], t)
  end
  -- H, O and I read the jobs themselves: the same rule there
  for _, panel in ipairs({ "H ALL", "O", "I" }) do
    t:type(panel):enter()
    s = t:screen()
    for i = 4, #s do
      local name = s[i]:match("^    (%S+)")
      want(not name or name:sub(1, #me) == me, panel .. " shows a job of another user: " .. s[i], t)
    end
  end
  title_after(t, "/D T", "NOT AUTHORIZED FOR CMD")
  t:type("DA"):enter()
  t:expect("SDSF DA")
  print(t:text())
  s = t:screen()
  local mine = false
  for i = 4, #s do
    want(not s[i]:find("^    %*MASTER%*") and not s[i]:find("^    JES2 "),
         "DA shows a system address space: " .. s[i], t)
    if s[i]:find("^    " .. me .. " ") then mine = true end
  end
  want(mine, "DA does not show the user's own TSO session", t)
  t:pf(3)
  t:expect("SDSF PRIMARY OPTION MENU")
end

return function(t)
  if t.user == "IBMUSER" then
    print("for a user without rights only: skipped for " .. t.user)
    return
  end
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
