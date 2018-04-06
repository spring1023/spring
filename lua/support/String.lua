StringManager = nil
do
    local stringCache = {}
    local function init(language)
        GEngine.lockG(false)
        function Entry(key, ...)
            stringCache[key] = select(language, ...)
        end
        if GEngine.rawConfig.DEBUG_STRING then
            require "data.mstrings"
            package.loaded["data.mstrings"] = nil
        else
            require "data.strings"
            package.loaded["data.strings"] = nil
        end
        Entry = nil
        GEngine.lockG(true)
    end
    local function init2(lpath)
        GEngine.lockG(false)
        function Entry(key, value)
            stringCache[key] = value
        end
        if GEngine.rawConfig.DEBUG_STRING then
            require "data.mstrings"
            package.loaded["data.mstrings"] = nil
        else
            require(lpath)
            package.loaded[lpath] = nil
        end
        Entry = nil
        GEngine.lockG(true)
    end

    local function getString(key)
        return stringCache[key] or key
    end

    local function formatString(s, param)
        local function stringFormat(k)
            local pk = string.sub(k, 2, -2)
            return param[pk] or k
        end
        local ret = string.gsub(s, "%[[a-zA-Z]+%]", stringFormat)
        return ret
    end

    local function getFormatString(key, param)
        return formatString(getString(key), param)
    end

    local timeSeq = {"tmSec", "tmMin", "tmHr", "tmDay"}
    local timeMod = {60, 60, 24, 10000}
    local function getTimeString(timeInSeconds, full)
        if not timeInSeconds or timeInSeconds<=0 then
            return getString("wordNone")
        else
            local ret, retSeq, retIndex, time = "", {}, 0, math.floor(timeInSeconds)
            for i=1, 4 do
                if full and i==3 then
                    retIndex = i
                    retSeq[i] = time .. getString(timeSeq[i])
                    break
                end
                local temp = time % timeMod[i]
                time = math.floor(time/timeMod[i])
                retIndex = i
                if temp~=0 or (i==1 and time==0) then
                    retSeq[i] = temp .. getString(timeSeq[i])
                end
                if time==0 then break end
            end
            ret = retSeq[retIndex]
            if retSeq[retIndex-1] then
                ret = ret .. getString("tmSplit") .. retSeq[retIndex-1]
            end
            if full and retIndex>=3 and retSeq[retIndex-2] then
                ret = ret .. getString("tmSplit") .. retSeq[retIndex-2]
            end
            return ret
        end
    end

    local function getNumberString(num)
        local s = ""
        local prefix = ""
        if num<0 then
            num = -num
            prefix = "-"
        end
        if num<1000 then
            s = tostring(num)
        else
            local num2
            while num>=1000 do
                num2 = num%1000
                s = " " .. string.format("%03d", num2) .. s
                num = (num-num2)/1000
            end
            s = tostring(num) .. s
        end
        return prefix .. s
    end

    StringManager = {init=init, init2=init2,getString=getString, formatString=formatString, getFormatString = getFormatString, getTimeString=getTimeString, getNumberString=getNumberString}

    function StringManager.getFormatTime(t)
        if t<0 then
            t = 0
        end
        return string.format("%02d:%02d:%02d", math.floor(t/3600), math.floor((t%3600)/60), math.floor(t%60))
    end

    function StringManager.addStrings(tb)
        if tb then
            for k, v in pairs(tb) do
                stringCache[k] = v
            end
        end
    end
end
