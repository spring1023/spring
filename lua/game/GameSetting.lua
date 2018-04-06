--[[
@brief: 系统设置类，用于将系统设置的内容进行持久化保存和读取
@author: a0yu3@qq.com
@date: 2017.12.1
@details: 详细的使用方法样例，可省略
--]]
local GameSetting={}
GameSetting.GskEffect="sc_gskAnimationOff"      --天神技动画默认为打开
--一些屏蔽项默认设置 但是在没有从服务器接受到数据时会被设置为1
GameSetting.shareConfig=1

--[[
@brief: 系统设置初始化，在LoadingGameController中会被调用
        根据需要添加初始化
]]--
function GameSetting.init()

end
--[[
@brief: 系统设置获取系统设置方法
@author: a0yu3@qq.com
@date: 2017.12.5
--]]
function GameSetting.getSetting(key,default)
    local ret=GEngine.getConfig(key)
    if not ret and default then
        ret=default
        GEngine.setConfig(key,ret,true)
    end
    return ret
end
--[[
@brief: 系统设置设置系统设置方法
@author: a0yu3@qq.com
@date: 2017.12.5
--]]
function GameSetting.setSetting(key,value)
    GEngine.setConfig(key,value,true)
end

do
    -- @brief 因为感觉原来的UserDefault又读又写十分麻烦，保存同步操作也比较复杂，分用户存储不是特别好用，所以干脆自己重新弄一套
    -- @brief 并且懒得再加一个文件了，说到底都是类似的封装分那么多干啥
    local _myConfigCache = {}
    -- @brief 读取本地数据
    -- @params fileKey 文件key；一般就是uid，通用的存0即可
    function GameSetting.getLocalData(fileKey, key)
        if not _myConfigCache[fileKey] then
            local cfs = cc.FileUtils:getInstance()
            local upath = cfs:getWritablePath() .. "my_config_" .. fileKey .. ".json"
            local uf = nil
            if cfs:isFileExist(upath) then
                uf = GMethod.loadConfig(upath)
            end
            if not uf then
                uf = {}
            end
            _myConfigCache[fileKey] = {data=uf, fileKey=fileKey}
        end
        return _myConfigCache[fileKey].data[key]
    end

    function GameSetting.setLocalData(fileKey, key, value, force)
        local ov = GameSetting.getLocalData(fileKey, key)
        if ov ~= value or type(ov) == "table" then
            _myConfigCache[fileKey].data[key] = value
            if force then
                _myConfigCache[fileKey].dirty = 0
            elseif not _myConfigCache[fileKey].dirty then
                _myConfigCache[fileKey].dirty = GameLogic.getSTime()
            end
        end
    end

    -- @每10秒存一次好了，反正这个值一般不重要
    function GameSetting.saveLocalData()
        local stime = GameLogic.getSTime()
        for _, v in pairs(_myConfigCache) do
            if v.dirty and v.dirty < stime - 10 then
                v.dirty = nil
                local cfs = cc.FileUtils:getInstance()
                local upath = cfs:getWritablePath() .. "my_config_" .. v.fileKey .. ".json"
                cfs:writeStringToFile(json.encode(v.data), upath)
            end
        end
    end
end

return GameSetting
