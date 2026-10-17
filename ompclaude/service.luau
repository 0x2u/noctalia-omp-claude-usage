-- omp Claude Usage — headless service (data owner).
--
-- Runs get-omp-claude-usage (with --json) on the configured interval, decodes the
-- result, and publishes it to the plugin's shared state so the bar widget and the
-- desktop widget can mirror it without each shelling out. Mirrors the
-- service-owns-logic pattern of the screen_recorder plugin.
--
--   noctalia.state.set("usage", <table>)   -- the parsed usage object
--   noctalia.state.set("status", {...})     -- loading / ready / error + availability
--
-- Drive a manual refresh from the shell:
--   noctalia msg plugin 0x2u/ompclaude:service all refresh

local scriptPath = `{noctalia.pluginDir()}/get-omp-claude-usage`
local depsOk = noctalia.commandExists("jq") and noctalia.commandExists("curl") and noctalia.commandExists("sqlite3")
local fetching = false
local started = false

local function publishStatus(state, message)
  noctalia.state.set("status", { state = state, available = depsOk, message = message or "" })
end

-- refresh_interval is in minutes (2–15); convert to the update() cadence in ms.
local function intervalMs()
  local mins = noctalia.getConfig("refresh_interval")
  if type(mins) ~= "number" or mins < 1 then
    mins = 2
  end
  return math.floor(mins * 60000)
end

local function fetch()
  if fetching then
    return
  end
  if not depsOk then
    publishStatus("error", "jq, curl and sqlite3 are required")
    return
  end

  fetching = true
  publishStatus("loading")

  local launched = noctalia.runAsync(`bash '{scriptPath}' --json`, function(result)
    fetching = false

    if type(result) ~= "table" or result.success == false or result.exitCode ~= 0 then
      noctalia.log("ompclaude: get-omp-claude-usage failed")
      publishStatus("error", "Fetch failed")
      return
    end

    local data = noctalia.json.decode(result.stdout or "")
    if type(data) ~= "table" then
      noctalia.log("ompclaude: could not decode JSON output")
      publishStatus("error", "Bad data")
      return
    end

    noctalia.state.set("usage", data)
    publishStatus("ready")
  end)

  if not launched then
    fetching = false
    publishStatus("error", "Could not launch get-omp-claude-usage")
  end
end

-- update() fires immediately at load and then on the interval: that gives us
-- "refresh on start, then every N minutes" for free.
function update()
  noctalia.setUpdateInterval(intervalMs())
  if not started then
    started = true
    if not depsOk then
      publishStatus("error", "jq, curl and sqlite3 are required")
    end
  end
  fetch()
end

-- The bar widget bumps this nonce on click to force an out-of-band refresh.
noctalia.state.watch("refresh_nonce", function()
  fetch()
end)

function onIpc(event)
  if event == "refresh" then
    fetch()
  end
end
