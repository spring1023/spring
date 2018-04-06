--[[
初级的日志模块，可以分级打日志；之后应该要扩展，以支持文件日志或远程日志之类的方法，从而将客户端错误同步到服务端。
--]]
local Log = {DEBUG=0, INFO=1, ERROR=2, CLOSE=3}
local logLevel = 3

local rawLog = print

local function flog(level, ...)
    if level>=logLevel then
        rawLog(string.format(...))
    end
end

function Log.setLogLevel(level)
    logLevel = level
end

function Log.e(...)
    return flog(2, ...)
end

function Log.i(...)
    return flog(1, ...)
end

function Log.d(...)
    return flog(0, ...)
end

return Log
