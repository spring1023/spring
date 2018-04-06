--@brief 把如果需要用到的“游戏内”下载包装一下，避免重复下载
local network = GMethod.loadScript("engine.network")

local DownloadUtil = {}
local _downCache = {}

-- @brief 内部下载百分比逻辑处理
local function _downloadPercent(downloadSetting, percent)
    local fkey = downloadSetting[1]
    local task = _downCache[fkey]
    if task then
        for obj, callbacks in pairs(task) do
            if not obj.deleted then
                callbacks[1](obj, percent)
            end
        end
    end
end

-- @brief 内部下载完成逻辑处理
local function _downloadFinish(downloadSetting, suc)
    local fkey = downloadSetting[1]
    local task = _downCache[fkey]
    if task then
        for obj, callbacks in pairs(task) do
            if not obj.deleted then
                if suc then
                    local cfs = cc.FileUtils:getInstance()
                    local myPath = cfs:getWritablePath()
                    local path = myPath .. fkey .. ".tmp"
                    -- 需要做md5检查
                    if downloadSetting[5] then
                        -- 小文件，不用分步计算，反而更慢
                        if downloadSetting[3] == 0 then
                            local tf = io.open(path, "rb")
                            local chunk = nil
                            if tf then
                                local chunk = tf:read("*a")
                                tf:close()
                            else
                                print("win32", path)
                            end
                            if chunk then
                                local signData = {}
                                for i=1, 16 do
                                    signData[i] = 0
                                end
                                local cl = chunk:len()
                                local j
                                for i=1, cl do
                                    j = (i-1)%16+1
                                    signData[j] = signData[j] + chunk:byte(i)
                                end
                                local sortedStr = ""
                                for i=1, 16 do
                                    local c = signData[i]
                                    c = math.floor(math.floor(c+0.5)%62+0.5)
                                    if c<10 then
                                        c = string.char(48+c)
                                    elseif c<36 then
                                        c = string.char(55+c)
                                    else
                                        c = string.char(61+c)
                                    end
                                    sortedStr = sortedStr .. c
                                end
                                print("!!!", sortedStr, downloadSetting[5])
                                if sortedStr ~= downloadSetting[5] then
                                    callbacks[2](obj, false)
                                    return
                                end
                            end
                        end
                    elseif downloadSetting[4] then
                        -- 是否支持md5功能
                        if false then
                            if md5(myPath .. fkey .. ".tmp") ~= downloadSetting[4] then
                                return
                            end
                        end
                    end
                    cfs:removeFile(myPath .. fkey)
                    cfs:renameFile(myPath .. fkey .. ".tmp", myPath .. fkey)
                end
                callbacks[2](obj, suc)
            end
        end
        _downCache[fkey] = nil
    end
end

-- @brief 添加下载任务
-- @params downloadSetting 标准下载配置，格式为{下载key，下载地址，长度，MD5}
-- @params obj 下载回调对象；如果对象没了就不回调了，防止出错
-- @params percentCallback 百分比回调方法
-- @params finishCallback 完成回调方法
function DownloadUtil.addDownloadTask(downloadSetting, obj, percentCallback, finishCallback)
    if not downloadSetting then
        return
    end
    local fkey = downloadSetting[1]
    -- 如果已有相同下载任务则复用任务，避免重复添加
    if _downCache[fkey] then
        _downCache[fkey][obj] = {percentCallback, finishCallback}
    else
        _downCache[fkey] = {}
        _downCache[fkey][obj] = {percentCallback, finishCallback}
        local cfs = cc.FileUtils:getInstance()
        local myPath = cfs:getWritablePath()
        local fpos, _ = fkey:find("/")
        while fpos do
            local fdir = fkey:sub(1, fpos-1)
            if not cfs:isDirectoryExist(myPath .. fdir) then
                cfs:createDirectory(myPath .. fdir)
            end
            fpos, _ = fkey:find("/", fpos+1)
        end
        network.httpRequest(downloadSetting[2], network.DOWNLOAD, {},
            {path=myPath .. fkey .. ".tmp", single=false, multi=true,
            callback=_downloadFinish, callbackParams={downloadSetting},
            percentCallback=_downloadPercent, percentParams={downloadSetting}, retry=3})
    end
end

-- @brief 添加小包下载逻辑
function DownloadUtil.addLittlePkgTask(remotePath, luaSign, obj, finishCallback)
    local cfs = cc.FileUtils:getInstance()
    local myPath = cfs:getWritablePath()
    local fpath = myPath .. luaSign .. ".pkg"
    -- TODO 文件已存在则无需下载; 理论上应该需要再自检一遍。不过下载的时候会检查所以自检可以先不实现
    if cfs:isFileExist(fpath) then
        finishCallback(obj, true)
        return
    end
    local url
    -- 测试服就从测试服下载
    if GEngine.rawConfig.rawUrl:find("www.caesarsplay.com") then
        url = "http://coz1vn.moyuplay.com/"
    else
        local deviceInfo = json.decode(Native:getDeviceInfo())
        -- 中国区则从中国CDN下载, 否则走亚马逊
        if deviceInfo.country == "CN" or deviceInfo.country == "HK" or deviceInfo.country == "TW" then
            url = "http://cdn.moyuplay.com/"
        else
            url = "http://d2pkf9xf7unp5y.cloudfront.net/"
        end
    end
    url = url .. remotePath
    DownloadUtil.addDownloadTask({luaSign .. ".pkg", url, 0, "", luaSign}, obj, GMethod.doNothing, finishCallback)
end

local function _autoLoadPkg(localKey, luaSign, obj, suc)
    if suc then
        local cfs = cc.FileUtils:getInstance()
        local myPath = cfs:getWritablePath()
        local fpath = myPath .. localKey
        if cfs:isFileExist(fpath) then
            local GameSetting = GMethod.loadScript("game.GameSetting")
            local setting = GameSetting.getLocalData(0, "normalPkgs")
            if not setting then
                setting = {}
            end
            setting[localKey] = luaSign
            GameSetting.setLocalData(0, "normalPkgs", setting, true)
            GameSetting.saveLocalData()
            GEngine.engine:getPackageManager():loadPackage(localKey)
            return
        end
    end
end

-- @brief 添加小包下载逻辑
function DownloadUtil.addNormalPkgTask(localKey, remotePath, luaSign)
    local cfs = cc.FileUtils:getInstance()
    local myPath = cfs:getWritablePath()
    local fpath = myPath .. localKey
    -- TODO 文件已存在则无需下载; 理论上应该需要再自检一遍。不过下载的时候会检查所以自检可以先不实现
    if cfs:isFileExist(fpath) then
        -- 做检测
        local GameSetting = GMethod.loadScript("game.GameSetting")
        local setting = GameSetting.getLocalData(0, "normalPkgs")
        if not setting then
            setting = {}
            GameSetting.setLocalData(0, "normalPkgs", setting, true)
        end
        if setting[localKey] == luaSign then
            GEngine.engine:getPackageManager():loadPackage(localKey)
            return
        else
            GEngine.engine:getPackageManager():unloadPackage(localKey)
            cfs:removeFile(fpath)
        end
    end
    local url
    -- 测试服就从测试服下载
    if GEngine.rawConfig.rawUrl:find("www.caesarsplay.com") then
        url = "http://coz1vn.moyuplay.com/"
    else
        local deviceInfo = json.decode(Native:getDeviceInfo())
        -- 中国区则从中国CDN下载, 否则走亚马逊
        if deviceInfo.country == "CN" or deviceInfo.country == "HK" or deviceInfo.country == "TW" then
            url = "http://cdn.moyuplay.com/"
        else
            url = "http://d2pkf9xf7unp5y.cloudfront.net/"
        end
    end
    url = url .. remotePath
    DownloadUtil.addDownloadTask({localKey, url, 0, "", luaSign}, {}, GMethod.doNothing,
        Handler(_autoLoadPkg, localKey, luaSign))
end


return DownloadUtil
