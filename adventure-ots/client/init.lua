-- this is the first file executed when the application starts
-- we have to load the first modules form here

-- updater
Services = {
    --updater = "http://localhost/api/updater.php", --./updater
    --status = "http://localhost/login.php", --./client_entergame | ./client_topmenu
    --websites = "http://localhost/?subtopic=accountmanagement", --./client_entergame "Forgot password and/or email"
    --createAccount = "http://localhost/clientcreateaccount.php", --./client_entergame -- createAccount.lua
    --getCoinsUrl = "http://localhost/?subtopic=shop&step=terms", --./game_market
}

--[[
Servers_init = {
    ["http://127.0.0.1/login.php"] = {
        ["port"] = 80,
        ["protocol"] = 1320,
        ["httpLogin"] = true
    },
    ["ip.net"] = {
        ["port"] = 7171,
        ["protocol"] = 860,
        ["httpLogin"] = false
    },
}
]]

g_app.setName("OTClient - Redemption");
g_app.setCompactName("otclient");
g_app.setOrganizationName("otcr");

g_app.hasUpdater = function()
    return (Services.updater and Services.updater ~= "" and g_modules.getModule("updater"))
end

-- setup logger
g_logger.setLogFile(g_resources.getWorkDir() .. g_app.getCompactName() .. '.log')

-- Default to info-level logs for troubleshooting builds.
-- Override with OTCLIENT_LOG_LEVEL (1=debug, 2=info, 3=warning, 4=error, 5=fatal).
do
    local defaultLevel = 2
    local configuredLevel = tonumber(os.getenv('OTCLIENT_LOG_LEVEL') or '') or defaultLevel

    if configuredLevel < 1 then configuredLevel = 1 end
    if configuredLevel > 5 then configuredLevel = 5 end

    g_logger.setLevel(configuredLevel)
    g_logger.info(string.format('== logger level set to %d', configuredLevel))
end

g_logger.info(os.date('== application started at %b %d %Y %X'))
g_logger.info("== operating system: " .. g_platform.getOSName())

-- print first terminal message
g_logger.info(g_app.getName() .. ' ' .. g_app.getVersion() .. ' rev ' .. g_app.getBuildRevision() .. ' (' ..
    g_app.getBuildCommit() .. ') built on ' .. g_app.getBuildDate() .. ' for arch ' ..
    g_app.getBuildArch())

-- setup lua debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
    g_logger.debug("Started LUA debugger.")
else
    g_logger.debug("LUA debugger not started (not launched with VSCode local-lua).")
end

-- add data directory to the search path
if not g_resources.addSearchPath(g_resources.getWorkDir() .. 'data', true) then
    g_logger.fatal('Unable to add data directory to the search path.')
end
g_logger.info("== search path added: " .. g_resources.getWorkDir() .. 'data')

-- add modules directory to the search path
if not g_resources.addSearchPath(g_resources.getWorkDir() .. 'modules', true) then
    g_logger.fatal('Unable to add modules directory to the search path.')
end
g_logger.info("== search path added: " .. g_resources.getWorkDir() .. 'modules')

g_html.addGlobalStyle('/data/styles/html.css')
g_html.addGlobalStyle('/data/styles/custom.css')

-- try to add mods path too
g_resources.addSearchPath(g_resources.getWorkDir() .. 'mods', true)
g_logger.info("== search path added: " .. g_resources.getWorkDir() .. 'mods')

-- setup directory for saving configurations
g_resources.setupUserWriteDir(('%s/'):format(g_app.getCompactName()))
g_logger.info("== user write dir: " .. g_resources.getWriteDir())

-- search all packages
g_resources.searchAndAddPackages('/', '.otpkg', true)
g_logger.info("== package discovery completed (.otpkg)")

-- load settings
g_configs.loadSettings('/config.otml')
g_logger.info("== settings loaded: /config.otml")

g_modules.discoverModules()

do
    local discovered = g_modules.getModules() or {}
    local discoveredCount = 0
    for _ in pairs(discovered) do
        discoveredCount = discoveredCount + 1
    end
    g_logger.info(string.format('== discovered modules: %d', discoveredCount))
end

-- libraries modules 0-99
g_modules.autoLoadModules(99)
g_modules.ensureModuleLoaded('corelib')
g_modules.ensureModuleLoaded('gamelib')
g_modules.ensureModuleLoaded('modulelib')
g_modules.ensureModuleLoaded("startup")

g_modules.autoLoadModules(999)
g_modules.ensureModuleLoaded('game_shaders') -- pre load

local function loadModules()
    -- client modules 100-499
    g_modules.autoLoadModules(499)
    g_modules.ensureModuleLoaded('client')

    -- game modules 500-999
    g_modules.autoLoadModules(999)
    g_modules.ensureModuleLoaded('game_interface')

    -- mods 1000-9999
    g_modules.autoLoadModules(9999)

    -- Some distributions no longer ship a dedicated client_mods module.
    -- Keep startup compatible by loading it only when discovered.
    if g_modules.getModule('client_mods') then
        g_modules.ensureModuleLoaded('client_mods')
    else
        g_logger.warning("Optional module 'client_mods' not found; continuing startup.")
    end

    local script = '/' .. g_app.getCompactName() .. 'rc.lua'

    if g_resources.fileExists(script) then
        dofile(script)
        g_logger.info("== user startup script loaded: " .. script)
    else
        g_logger.info("== user startup script not found: " .. script)
    end

    do
        local loadedCount = 0
        for _, module in pairs(g_modules.getModules() or {}) do
            if module and module:isLoaded() then
                loadedCount = loadedCount + 1
            end
        end
        g_logger.info(string.format('== loaded modules: %d', loadedCount))
    end

    -- uncomment the line below so that modules are reloaded when modified. (Note: Use only mod dev)
    -- g_modules.enableAutoReload()
end

-- run updater, must use data.zip
if g_app.hasUpdater() then
    g_modules.ensureModuleLoaded("updater")
    return Updater.init(loadModules)
end

loadModules()
g_logger.info('== startup sequence completed')

-- Adventure OTS: default server target
-- Protocol 1098 = Tibia client version 10.98 (fixed)
do
    local defaultHost = '127.0.0.1'
    local defaultPort = 7171
    local fixedProtocol = 1098

    local host = os.getenv('OTCLIENT_SERVER_HOST') or defaultHost
    if host == '' then
        host = defaultHost
    end

    local port = tonumber(os.getenv('OTCLIENT_SERVER_PORT') or '') or defaultPort
    if port < 1 or port > 65535 then
        g_logger.warning(string.format('Invalid OTCLIENT_SERVER_PORT (%s); using default %d.', tostring(port), defaultPort))
        port = defaultPort
    end

    EnterGame.setUniqueServer(host, port, fixedProtocol)
    g_logger.info(string.format('== default server configured: %s:%d (protocol %d)', host, port, fixedProtocol))
end
