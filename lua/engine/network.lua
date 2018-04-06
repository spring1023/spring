local json = _G["json"]

local network = {GET=0, POST=1, DOWNLOAD=2}
local _requestList = {}
local _requests = {}
function network.registerNormalHandler(tag, func)
    network[tag] = func
end

local _makeRequest
local function _dealCallback(luaRequest, request)
    local isSuc = request:isSuccess()
    local data = nil
    local code = 0
    local lsetting = luaRequest.otherSettings
    if isSuc then
        code = request:getResponseCode()
        if code==200 then
            data = request:getResponseString()
        else
            isSuc = false
        end
    else
        --time out, need retry first
        if lsetting.retry and lsetting.retry < 3 then
            lsetting.retry = lsetting.retry + 1
            request:release()
            local client
            client, request = _makeRequest(luaRequest)
            client:sendRequest(request)
            return
        end
    end
    if lsetting.normal and network.afterRequest then
        isSuc, data = network.afterRequest(code, data, luaRequest)
    end
    _requests[luaRequest] = nil
    request:release()
    if lsetting.single then
        log.d("request finished with url:%s",luaRequest.url)
        table.remove(_requestList, 1)
        if #_requestList>0 then
            HttpModule:getInstance():sendRequest(_requestList[1].request)
        end
    end
    if lsetting.callback then
        Script.executeBasicCallback(lsetting.callback, lsetting.callbackParams, isSuc, data)
    end
end

local function _dealDownload(luaRequest, request, percent)
    if percent then
        local lsetting = luaRequest.otherSettings
        if lsetting.percentCallback then
            Script.executeBasicCallback(lsetting.percentCallback, lsetting.percentParams, percent)
        end
    else
        _dealCallback(luaRequest, request)
    end
end

--通过参数生成一个request
_makeRequest = function(luaRequest)
    local client = HttpModule:getInstance()
    local request = client:createHttpProgress(luaRequest.multi, false, luaRequest.method, luaRequest.url)
    luaRequest.request = request
    if luaRequest.params then
        for k,v in pairs(luaRequest.params) do
            if type(v)=="table" then
                request:setParam(k,json.encode(v))
            else
                request:setParam(k,tostring(v))
            end
        end
    end
    if luaRequest.method==network.DOWNLOAD then
        local dpath = luaRequest.otherSettings["path"]
        request:setDownloadPath(dpath)
        request:setScriptCallback(Script.createCallbackHandler(_dealDownload, luaRequest))
    else
        request:setScriptCallback(Script.createCallbackHandler(_dealCallback, luaRequest))
    end
    request:retain()
    return client, request
end

--包装了通常发送一次http请求的操作
function network.httpRequest(url,method,params,otherSettings)
    local luaRequest = {url=url, method=method, params=params, otherSettings=otherSettings}
    local single = otherSettings.single
    local multi = false
    if not single then
        if method==network.GET and (otherSettings.multi==nil or otherSettings.multi==true) then
            multi = true
        end
    end
    luaRequest.multi = multi
    local client, request = _makeRequest(luaRequest)
    _requests[luaRequest] = 1
    if single then
        if #_requestList>0 then
            table.insert(_requestList, luaRequest)
        else
            _requestList[1] = luaRequest
            client:sendRequest(request)
        end
    else
        client:sendRequest(request)
    end
end

--取消所有请求；注：取消请求之后将不会收到回调
function network.cancelAll()
    for request,_  in pairs(_requests) do
        request.request:cancel()
        request.request:release()
    end
    _requests = {}
    _requestList = {}
end

--获取single请求；single请求指的是逻辑上需要等前一个请求处理完毕后再发送的请求；
--通常来讲，所有游戏逻辑提交数值时都应该做成single请求
function network.getSingleRequest()
    return _requestList[1]
end
return network
