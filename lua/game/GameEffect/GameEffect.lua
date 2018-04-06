
local GameEffect=class()
local GMethod = _G["GMethod"]
local ui = _G["ui"]
local music = _G["music"]

function GameEffect:ctor(ConfigFile,path)
    local effectConfigPath
    if path then
        effectConfigPath = path
    else
        effectConfigPath = "game/GameEffect/effectsConfig/"
    end
    self.config = GMethod.loadConfig(effectConfigPath .. ConfigFile)
    if not self.config then
        self.config = GMethod.loadConfig(effectConfigPath .. ConfigFile .. ".json")
    end
    self.views = {}
    self.params = {}
    self.scene = GMethod.loadScript("game.View.Scene")
end

function GameEffect:checkID(id)
    if self.views[id] then
        --print("id:" ..id.. "   Repeat")
        --return true
    end
end
--params={["1"]={x=100,y=100,z=2,r=90,scale=0.8},["2"]={x=200,y=200,z=2,tab={}}} --格式参考
function GameEffect:addMusic(sView)
    local config=self.config
    if config and config["musicConfig"] then
        for i,item in ipairs(config["musicConfig"]) do
            if item["startView"]==sView then
                local function py()
                    music.play(item["music"])
                end
                self.scene.objs:runAction(ui.action.sequence({{"delay",item["delayTime"] or 0},{"call",py}}))
            end
        end
    end
end

function GameEffect:addEffect(viewsName,bg,params)
    local config=self.config
    self.bg=bg

    if config and config[viewsName] then
        self:addMusic(viewsName)
        for i,item in ipairs(config[viewsName]) do
            -- if self:checkID(item.id) then
            --  --return
            -- end
            local temp
            if params and item.id then
                self.params[tostring(item.id)]=params[tostring(item.id)]
            end
            if item.type=="image" then
                temp = self:addImageEffect(item)
            elseif item.type=="particle" then
                temp = self:addParticleEffect(item)
            elseif item.type=="animate" then
                temp = self:addAnimateEffect(item)
            end
            if item.gz then
                temp:setGlobalZOrder(item.gz)
            end
            if item.id then
                self.views[item.id] = temp
            end
        end
    end
end
function GameEffect:addImageEffect(item)                --图片
    local bg=self.bg
    local params=self.params[tostring(item.id)] or {}
    local temp
    if item.sx and item.sy then
        temp=ui.sprite(item.image or item.resPath,{item.sx,item.sy})
    else
        temp=ui.sprite(item.image or item.resPath)
    end
    if not temp then
        print("no effect", item.image, item.resPath)
        return
    end
    bg:addChild(temp,params.z or item.z or 0)
    temp:setAnchorPoint(item.ax or 0.5,item.ay or 0.5)
    temp:setPosition(params.x or item.x,params.y or item.y)
    temp:setRotation(params.r or item.r or 0)
    if params.scale or item.scale then
        temp:setScale(params.scale or item.scale)
    end
    if params.scaleX or item.scaleX then
        temp:setScaleX(params.scaleX or item.scaleX)
    end
    if params.scaleY or item.scaleY then
        temp:setScaleY(params.scaleY or item.scaleY)
    end

    if item.color then
        temp:setColor(cc.c3b(item.color[1],item.color[2],item.color[3]))
    end
    if item.opacity then
        temp:setOpacity(item.opacity)
    end
    if item.visible==false then
        temp:setVisible(false)
    else
        temp:setVisible(true)
    end
    if item.blend then
        local blend={}
        blend.src=item.blend[1]
        blend.dst=item.blend[2]
        temp:setBlendFunc(blend)
    end
    if item.action and next(item.action) ~=nil then
        temp:runAction(ui.action.action(item.action))
    end
    return temp
end
function GameEffect:addParticleEffect(item)           --粒子
    local bg=self.bg
    local params=self.params[tostring(item.id)] or {}
    local temp
    if item.plist or item.resPath then
        temp=ui.particle(item.plist or item.resPath, item.params)
        bg:addChild(temp,params.z or item.z or 0)
    elseif item["json"] then
        temp= ui.particle("heroeffects/dragonBurnBack.json",params["tab"] or {})
        bg:addChild(temp,params.z or item.z or 0)
    end
    temp:setAnchorPoint(item.ax or 0.5,item.ay or 0.5)
    temp:setPosition(params.x or item.x,params.y or item.y)
    temp:setRotation(params.r or item.r or 0)
    temp:setPositionType(tonumber(item.positionType) or cc.POSITION_TYPE_GROUPED)
    if params.scale or item.scale then
        temp:setScale(params.scale or item.scale)
    end
    if params.scaleX or item.scaleX then
        temp:setScaleX(params.scaleX or item.scaleX)
    end
    if params.scaleY or item.scaleY then
        temp:setScaleY(params.scaleY or item.scaleY)
    end
    if item.blend then
        local blend={}
        blend.src=item.blend[1]
        blend.dst=item.blend[2]
        temp:setBlendFunc(blend)
    end
    if item.action and next(item.action) ~=nil then
        temp:runAction(ui.action.action(item.action))
    end
    return temp
end
function GameEffect:addAnimateEffect(item)                    --帧动画
    local bg=self.bg
    local params=self.params[tostring(item.id)] or {}
    --local temp = ui.animateSprite(item.time,item.name,item.frames,{beginNum=item.beginNum,plist=item.plist,isRepeat=item.isRepeat})
    local temp = ui.animateSprite(item.time,params.name or item.name,item.frames,item.tab)
    bg:addChild(temp,params.z or item.z or 0)
    temp:setAnchorPoint(item.ax or 0.5,item.ay or 0.5)
    temp:setPosition(params.x or item.x,params.y or item.y)
    temp:setRotation(params.r or item.r or 0)
    if params.scale or item.scale then
        temp:setScale(params.scale or item.scale)
    end
    if item.color then
        temp:setColor(cc.c3b(item.color[1],item.color[2],item.color[3]))
    end
    if params.scaleX or item.scaleX then
        temp:setScaleX(params.scaleX or item.scaleX)
    end
    if params.scaleY or item.scaleY then
        temp:setScaleY(params.scaleY or item.scaleY)
    end
    if item.opacity then
        temp:setOpacity(item.opacity)
    end
    if item.blend then
        local blend={}
        blend.src=item.blend[1]
        blend.dst=item.blend[2]
        temp:setBlendFunc(blend)
    end
    if item.action and next(item.action) ~=nil then
        temp:runAction(ui.action.action(item.action))
    end
    return temp
end
function GameEffect:findEffect(id)
    return self.views[id]
end

return GameEffect
