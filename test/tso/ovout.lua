-- test/tso/ovout.lua -- DEST on O and H, as in IBM's SDSF V1R2 and
-- as far as JES2 4.1 has a command for it: on O DEST is overtyped as on ST
-- ($RALL,J=,D=). On H a new DEST goes only with O in NP, which releases
-- the held output ($O, after the $R); without O the title says "O" ACTION
-- REQUIRED and the value stays. Only the test system's own output is
-- used: ZSWA's on O, an old session of this user's on H (released, it
-- moves to O, and its DEST is put back there).
local function want(cond, what, t)
  if not cond then print(t:text()); error(what) end
end

local function rowof(t, pat)
  local s = t:screen()
  for r = 4, #s do if s[r]:find(pat) then return r end end
end

local function goto_field(t, r, c)
  for _ = 1, 200 do
    t:tab()
    local cr, cc = t:cursor()
    if cr == r and cc == c then return end
  end
  error("no field at " .. r .. "," .. c)
end

local function home(t)
  for _ = 1, 200 do
    local r, c = t:cursor()
    if r == 2 and c == 21 then return end
    t:tab()
  end
end

local function dest(t, r, c)
  return (t:screen()[r]:sub(c, c + 7):gsub("%z", " "):gsub("%s+$", ""))
end

-- O: DEST of the row matching pat to new, then Enter shows it
local function o_dest(t, pat, new)
  local r = rowof(t, pat)
  want(r, "no row " .. pat .. " on O", t)
  goto_field(t, r, 41)
  t:type(new .. string.rep(" ", 8 - #new)):enter()
  want(t:screen()[1]:find("COMMAND ISSUED", 1, true), "O DEST " .. new .. ": " .. t:screen()[1], t)
  home(t); t:enter()
  r = rowof(t, pat)
  -- U1 shows as R1, as on ST: SDSF names any route but LOCAL Rn so far
  local shown = r and dest(t, r, 41) or "?"
  want(new == "LOCAL" and shown == "LOCAL" or new ~= "LOCAL" and shown ~= "LOCAL",
       "O shows DEST " .. shown .. " after " .. new, t)
end

local function body(t)
  -- O: a ZSWA job's output, LOCAL to U1 and back
  t:type("PRE ZSWA"):enter()
  t:type("O"):enter()
  t:expect("SDSF OUTPUT")
  local r = rowof(t, " ZSWA .* JOB ")
  want(r, "no ZSWA on O", t)
  local num = t:screen()[r]:match(" JOB +(%d+) ")
  local pat = " JOB +" .. num .. " "
  want(dest(t, r, 41) == "LOCAL", "ZSWA " .. num .. " is not LOCAL", t)
  o_dest(t, pat, "U1")
  o_dest(t, pat, "LOCAL")
  home(t); t:pf(3)

  -- H: an old session of this user: DEST without O is refused
  t:type("PRE IBMUSER"):enter()
  t:type("H"):enter()
  t:expect("SDSF HELD OUTPUT DISPLAY")
  local rows = {}
  for i = 4, #t:screen() do
    local n = t:screen()[i]:match("^%s+IBMUSER +TSU +(%d+) ")
    if n then rows[#rows + 1] = n end
  end
  want(#rows > 0, "no held output of an old session", t)
  local tsu = rows[1]
  pat = " TSU +" .. tsu .. " "
  r = rowof(t, pat)
  goto_field(t, r, 48)
  t:type("U1      "):enter()
  want(t:screen()[1]:find('"O" ACTION REQUIRED', 1, true), "DEST without O: " .. t:screen()[1], t)
  want(dest(t, r, 48) == "U1", "the DEST typed is gone", t)
  goto_field(t, r, 48)
  t:type("LOCAL   "):enter()
  want(not t:screen()[1]:find("COMMAND ISSUED", 1, true), "LOCAL again sent something", t)
  -- with O: routed, then released
  r = rowof(t, pat)
  goto_field(t, r, 2)
  t:type("O")
  goto_field(t, r, 48)
  t:type("U1      "):enter()
  want(t:screen()[1]:find("COMMAND ISSUED", 1, true), "O with DEST: " .. t:screen()[1], t)
  home(t); t:enter()
  want(not rowof(t, pat), "the released output is still on H", t)
  home(t); t:pf(3)

  -- on O now, with DEST U1: put back to LOCAL
  t:type("O"):enter()
  t:expect("SDSF OUTPUT")
  r = rowof(t, pat)
  want(r and dest(t, r, 41) ~= "LOCAL", "the released output is not on O with U1", t)
  o_dest(t, pat, "LOCAL")
  home(t); t:pf(3)
  t:type("PRE"):enter()
end

return function(t)
  t:logon(); t:clear()
  t:type("ISPF"):enter()
  t:expect("Primary Option Menu")
  t:type("S"):enter()
  t:expect("SDSF PRIMARY OPTION MENU")
  local ok, err = pcall(body, t)
  if not ok then
    print(err); print(t:text())
    for _ = 1, 3 do
      if t:text():find("SDSF PRIMARY OPTION MENU", 1, true) then break end
      home(t); t:type(string.rep(" ", 30)); t:pf(3)
    end
    t:type("PRE"):enter()
  end
  for _ = 1, 4 do
    if t:text():find("Primary Option Menu", 1, true) then break end
    t:pf(3)
  end
  t:expect("Primary Option Menu")
  t:type("X"):enter()
  t:logoff()
  if not ok then error(err) end
end
