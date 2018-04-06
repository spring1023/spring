local memory = {}

local textureCache = cc.Director:getInstance():getTextureCache()
local frameCache = cc.SpriteFrameCache:getInstance()
local asyncLoader = ResAsyncLoader:getInstance()
local removeCache = {}
local releaseCache = {}

function memory.getTextureCache()
    return textureCache
end

function memory.getFrameCache()
    return frameCache
end

function memory.getFrame(frameName, noCheck)
    local frame = frameCache:getSpriteFrame(frameName)
    if not frame and not noCheck then
        log.e("frame not exist:%s", frameName)
    end
    return frame
end

function memory.loadSpriteSheet(plist, texture, toRemoveCache, node, callback)
    if node then
        asyncLoader:addLuaTask(node, plist, texture, callback)
    elseif texture then
        frameCache:addSpriteFrames(plist, texture)
    else
        frameCache:addSpriteFrames(plist)
    end
    if toRemoveCache then
        table.insert(removeCache,plist)
    end
end

function memory.loadSpriteSheetRelease(plist, notAdd, node, callback)
    local add = 1
    if notAdd then
        add = 0
    end
    if releaseCache[plist] then
        releaseCache[plist] = releaseCache[plist] + add
        return false
    end
    if node then
        asyncLoader:addLuaTask(node, plist, nil, callback)
    else
        frameCache:addSpriteFrames(plist)
    end
    releaseCache[plist] = add
    return true
end

function memory.releasePlist(plist)
    if releaseCache[plist] then
        releaseCache[plist] = releaseCache[plist]-1
    else
        releaseCache[plist] = 0
    end
end

function memory.removeUnusePlist()
    for plist, v in pairs(releaseCache) do
        if v<=0 then
            releaseCache[plist] = nil
            memory.releaseSpriteSheet(plist)
        end
    end
end

function memory.loadTexture(texture)
    return textureCache:addImage(texture)
end

function memory.releaseTexture(textureName)
    textureCache:removeTextureForKey(textureName)
end

function memory.releaseSpriteSheet(plist)
    frameCache:removeSpriteFramesFromFile(plist)
end

function memory.releaseCacheFrame()
    for i,v in ipairs(removeCache) do
        memory.releaseSpriteSheet(v)
    end
    memory.removeUnusePlist()
    removeCache = {}
    textureCache:removeUnusedTextures()
end


return memory
