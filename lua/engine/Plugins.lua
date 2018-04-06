--sdk一些功能的包装
Plugins = {}

function Plugins:init()
	local configs = GMethod.loadConfig("configs/plugins.json")
    local pluginSlot = GEngine.engine:getPluginSlot()
    Plugins.slot = pluginSlot
    local splugin
    if configs then
        for _, plugin in ipairs(configs) do
            splugin = pluginSlot:getPlugin(plugin.name)
            if splugin then
                Plugins[plugin.ptype] = splugin
                if plugin.config then
                    splugin:changeConfigs(json.encode(plugin.config))
                end
            end
        end
    else
        print("not plugins.json")
    end
end