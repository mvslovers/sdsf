-- mbt/init.lua -- the WTOR test needs a job of its own waiting for a reply,
-- I and the overtype test a held job (ZSIN, see held_zsin).
-- Before the TSO tests this submits test/jcl/zswa.jcl (with the target's
-- job and message class) and waits until its WTOR is outstanding; after
-- them it answers whatever is left of it, so no job stays waiting.

local TEXT = "ISFWTOR SDSF WTOR AUTO"

-- the reply id of the test's WTOR, from D R,L; nil if there is none
local function reply_id(ctx)
  local lines = ctx.console("D R,L")
  for _, l in ipairs(lines or {}) do
    local id = l:match("(%d+),%s*" .. TEXT)
    if id then return id end
  end
end

local function pause(ctx, s)
  ctx.exec{ "sleep", tostring(s) }
end

-- a target without a console through mvsMF gets
-- no job: the hooks warn and let the tests run
local function reachable(ctx)
  local ok = pcall(ctx.console, "D T")
  if not ok then ctx.warn("no console on this target: ZSWA not submitted") end
  return ok
end

-- I and the overtype test need a job held on the input queue: ZSIN
-- (test/jcl/zsin.jcl) stays there; submitted only if there is none (mvsMF
-- lists it as ACTIVE, one that ran as OUTPUT)
local function held_zsin(ctx)
  local status, body = ctx.mvs.request{ method = "GET",
                                        path = "/restjobs/jobs?prefix=ZSIN&owner=*" }
  if status ~= 200 then
    ctx.warn("the jobs ZSIN could not be listed: HTTP " .. tostring(status))
    return
  end
  for st in (body or ""):gmatch('"status"%s*:%s*"(%u+)"') do
    if st ~= "OUTPUT" then return end
  end
  local t = ctx.target()
  local jcl = ctx.fs.read("test/jcl/zsin.jcl")
  jcl = jcl:gsub("CLASS=A,MSGCLASS=H",
                 "CLASS=" .. (t.jobclass or "A") .. ",MSGCLASS=" .. (t.msgclass or "H"), 1)
  status, body = ctx.mvs.request{ method = "PUT", path = "/restjobs/jobs",
                                  body = jcl, content_type = "text/plain" }
  if status ~= 200 and status ~= 201 then
    ctx.warn("ZSIN was not submitted: HTTP " .. tostring(status))
    return
  end
  ctx.log("submitted the held ZSIN " .. (body:match('"jobid"%s*:%s*"([^"]+)"') or "?"))
end

mbt.hook("before_test", function(ctx)
  if ctx.kind ~= "tso" or ctx.dry_run or not reachable(ctx) then return end
  held_zsin(ctx)
  if reply_id(ctx) then
    ctx.log("a WTOR of ZSWA is already outstanding")
    return
  end
  local t = ctx.target()
  local jcl = ctx.fs.read("test/jcl/zswa.jcl")
  jcl = jcl:gsub("CLASS=A,MSGCLASS=H",
                 "CLASS=" .. (t.jobclass or "A") .. ",MSGCLASS=" .. (t.msgclass or "H"), 1)
  local status, body = ctx.mvs.request{ method = "PUT", path = "/restjobs/jobs",
                                        body = jcl, content_type = "text/plain" }
  if status ~= 200 and status ~= 201 then
    error("ZSWA was not submitted: HTTP " .. tostring(status) .. " " .. tostring(body))
  end
  ctx.log("submitted ZSWA " .. (body:match('"jobid"%s*:%s*"([^"]+)"') or "?"))
  for _ = 1, 30 do
    if reply_id(ctx) then return end
    pause(ctx, 2)
  end
  ctx.warn("the WTOR of ZSWA did not come within a minute; the WTOR test will fail")
end)

mbt.hook("after_test", function(ctx)
  if ctx.kind ~= "tso" or ctx.dry_run then return end
  local ok, id = pcall(reply_id, ctx)
  if not ok then return end
  if id then
    ctx.console("R " .. id .. ",SDSF TEST DONE")
    ctx.log("answered the WTOR " .. id .. " of ZSWA")
  end
end)

-- mbt run jown: submits tools/jcl/isfjown.jcl and prints its SYSPRINT,
-- every job with its owner and RAKF's answers in JESSPOOL
mbt.command("jown", function(ctx)
  local t = ctx.target()
  local jcl = ctx.fs.read("tools/jcl/isfjown.jcl")
  jcl = jcl:gsub("CLASS=A,MSGCLASS=H",
                 "CLASS=" .. (t.jobclass or "A") .. ",MSGCLASS=" .. (t.msgclass or "H"), 1)
  local status, body = ctx.mvs.request{ method = "PUT", path = "/restjobs/jobs",
                                        body = jcl, content_type = "text/plain" }
  if status ~= 200 and status ~= 201 then
    error("ISFJOWN was not submitted: HTTP " .. tostring(status) .. " " .. tostring(body))
  end
  local id = body:match('"jobid"%s*:%s*"([^"]+)"')
  ctx.log("submitted ISFJOWN " .. tostring(id))
  for _ = 1, 30 do
    pause(ctx, 2)
    status, body = ctx.mvs.request{ method = "GET", path = "/restjobs/jobs/ISFJOWN/" .. id }
    if status == 200 and body:find('"OUTPUT"', 1, true) then break end
  end
  status, body = ctx.mvs.request{ method = "GET", path = "/restjobs/jobs/ISFJOWN/" .. id .. "/files" }
  for obj in (body or ""):gmatch("{[^{}]*}") do
    local fid, dd = obj:match('"id"%s*:%s*(%d+)'), obj:match('"ddname"%s*:%s*"([^"]+)"')
    if dd == "SYSPRINT" or dd == "JESMSGLG" then
      local s, recs = ctx.mvs.request{ method = "GET",
        path = "/restjobs/jobs/ISFJOWN/" .. id .. "/files/" .. fid .. "/records" }
      print(recs)
    end
  end
end)

-- mbt run panels [DSN] [PATTERN]: puts the panels of ispplib/ into the
-- library of the target's ISPPLIB concatenation, ISF.DEV.ISPPLIB unless
-- named; PATTERN (default ispplib/*) limits them, as ispplib/isfh*
mbt.command("panels", function(ctx)
  local args = ctx.args or {}
  local dsn = args[1] or "ISF.DEV.ISPPLIB"
  local files = ctx.fs.list(args[2] or "ispplib/*")
  if #files == 0 then error("no panels match " .. tostring(args[2])) end
  for _, f in ipairs(files) do
    local member = f:match("([^/]+)$"):upper()
    local status, body = ctx.mvs.request{ method = "PUT",
      path = "/restfiles/ds/" .. dsn .. "(" .. member .. ")",
      body = ctx.fs.read(f), content_type = "text/plain" }
    if status ~= 201 and status ~= 204 then
      error(dsn .. "(" .. member .. "): HTTP " .. tostring(status) .. " " .. tostring(body))
    end
    ctx.log(dsn .. "(" .. member .. ")")
  end
end)
