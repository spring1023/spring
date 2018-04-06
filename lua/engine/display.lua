local display = {}
local _director = cc.Director:getInstance()
local _baseScene = nil
local _baseSize = {2048, 1536}
local _winSize = nil
local _scaleCache = {}
local _dialogDepth = 0
local _dialogs = nil
local _residentDialog = nil

-- 提示，纯文字，高于所有场景
local _notices

_director:setDisplayStats(false)

-- @brief 给iphoneX贴四个切角
function display.fixIphoneX()
    if cc.FileUtils:getInstance():isFileExist("images/iphoneXMic.png") and display.fixedIphoneX then
        local temp
        local bg = ui.node(display.winSize)
        local edge = math.floor(24*ui.normalScale)
        for i=1, 4 do
            for j=1, 4 do
                temp = ui.sprite("images/iphoneXMic.png", {edge, edge})
                ui.setColor(temp, GConst.Color.Black)
                temp:setAnchorPoint(1, 0)
                temp:setRotation(90*j)
                temp:setPosition((i == 1 or i == 4) and display.winSize[1] - 1 or 1,
                    i <= 2 and 1 or display.winSize[2] - 1)
                bg:addChild(temp)
            end
        end
        _baseScene:addChild(bg, 10000, 10000)
    end
end

function display.init(suitableSize)
    _baseScene = cc.Scene:create()
    if _director:getRunningScene() then
        _director:replaceScene(_baseScene)
    else
        _director:runWithScene(_baseScene)
    end
    _winSize = _director:getVisibleSize()
    display.winSize = {_winSize.width, _winSize.height}
    _winSize = display.winSize

    if suitableSize then
        _baseSize = suitableSize
    end

    local scale = 1
    --横屏模式
    if _winSize[1] > _winSize[2] then
        if _winSize[2]*4 >= _winSize[1]*3 then
            scale = _winSize[1]/1024
        elseif _winSize[2]*3 >= _winSize[1]*2 then
            local k = (9 - _winSize[2]*12/_winSize[1])
            scale = _winSize[1]*(1-k)/1024 + _winSize[2]*k/540
        else
            scale = _winSize[2]/540
        end
    end
    local isWide = false
    local hwb = _winSize[2]/_winSize[1]
    if _winSize[2]<=576 or (hwb<=2/3+0.01 and _winSize[2]<=800) or hwb<10/16-0.01 then
        isWide = true
    end
    ui.normalScale = scale
    ui.isWide = isWide
    _dialogDepth = 0
    _dialogs = {}
    _notices = {}
end

function display.clear()
    _baseScene:removeAllChildren(true)
    _baseScene = cc.Scene:create()
    if _director:getRunningScene() then
        _director:replaceScene(_baseScene)
    else
        _director:runWithScene(_baseScene)
    end
    _dialogDepth = 0
    _dialogs = {}
    _notices = {}
    display.fixIphoneX()
end

function display.getBaseScene( )
    return _baseScene
end

--添加“层”
function display.addLayer(view, depth, tag)
    local touchNode
    if view.setTouchPriority then
        touchNode = view
        touchNode:setTouchPriority(-depth)
    else
        touchNode = ui.touchNode(_winSize, -depth)
        touchNode:addChild(view,0,1)
    end
    _baseScene:addChild(touchNode, depth, tag)
    return touchNode
end

function display.removeLayer(tag)
    local child = _baseScene:getChildByTag(tag)
    if child then
        child:removeFromParent(true)
    end
end

function display.getScalePolicy(width, height)
    if not width or width<=0 then width = _baseSize[1] end
    if not height or height<=0 then height = _baseSize[2] end
    local policyKey = width .. "_" .. height
    local policy = _scaleCache[policyKey]
    if not policy then
        policy = {}
        local scale1, scale2 = _winSize[1]/width, _winSize[2]/height
        policy[GConst.Scale.Height] = scale2
        policy[GConst.Scale.Width] = scale1
        if scale1>scale2 then
            scale1, scale2 = scale2, scale1
        end
        policy[GConst.Scale.Big] = scale2
        policy[GConst.Scale.Small] = scale1
        _scaleCache[policyKey] = policy
    end
    return policy
end

function display.adapt(node, x, y, anchor, params)
    if not anchor then
        anchor = GConst.Anchor.LeftBottom
    end
    local scale = 1
    if params then
        local datum = params.datum or anchor
        if params.scale then
            scale = params.scale
        elseif params.scaleType then
            if params.scaleType==GConst.Scale.Dialog then
                local size = node:getContentSize()
                scale = ui.getUIScale2()
                if size.width*scale>_winSize[1] or size.height*scale>_winSize[2] then
                    local scales = display.getScalePolicy()
                    scale = scales[GConst.Scale.Small]
                    --display.getScalePolicy(size.width, size.height)[GConst.Scale.Small]
                end
            else
                scale = display.getScalePolicy()[params.scaleType]
            end
        end
        node:setScaleX(node:getScaleX()*scale)
        node:setScaleY(node:getScaleY()*scale)
        x = _winSize[1]*datum[1]+x*scale
        y = _winSize[2]*datum[2]+y*scale
    end
    node:setAnchorPoint(anchor[1], anchor[2])
    node:setPosition(x, y)
    return scale
end

--按优先级关闭对话框，可支持多级对话框关闭
function display.closeDialog(pri, closeWhenShow)
    pri = pri or 1
    local cpri,cdialog
    for i=_dialogDepth, 1, -1 do
        if not _dialogs[i] then
            return
        end
        cpri = _dialogs[i].priority or 1
        if cpri>=pri then
            cdialog = _dialogs[i]
            if cdialog.canExit and not cdialog:canExit(pri) then
                return
            end
            if cdialog.view.canExit and not cdialog.view:canExit(pri) then
                return
            end
            _dialogs[i] = nil
            _dialogDepth = _dialogDepth-1

            if cdialog.parent and cdialog.parent.onChildDialogExit then
                cdialog.parent:onChildDialogExit()
            end
            local t = 0
            if cdialog.exitAnimate then
                t = cdialog:exitAnimate()
            elseif not cdialog.fullscreen then
                t = 0.15
                local ts = cdialog.baseScale
                cdialog.view:runAction(ui.action.sequence({{"scaleTo",t/2,ts*1.1,ts*1.1},{"scaleTo",t/2,ts,ts}}))
                cdialog.view:runAction(ui.action.sequence({{"fadeOut",t},"remove"}))
            end
            if t>0 then
                if cdialog.dark then
                    cdialog.dark:runAction(ui.action.sequence({{"delay",t},{"fadeTo",0.15,0}}))
                end
                cdialog.dback:runAction(ui.action.sequence({{"delay",t+0.15},"remove"}))
            else
                cdialog.dback:removeFromParent(true)
            end
            cdialog.deleted = true
            cdialog.view.deleted = true
            if not closeWhenShow and not cdialog.swallow then
                Event.sendEvent(Event.EventDialogClose, true)
            end
            if pri==0 then break end
        else
            break
        end
    end
end

--对话框进出动画，接受可定制方法
function display.showDialog(dialog, autoPop, fullscreen, opPct)
    if display.lock then return end
    if autoPop==nil then autoPop=true end
    if type(dialog)=="table" and not dialog.view then
        if dialog.new then
            dialog = dialog.new()
        else
            dialog:create()
        end
    end
    if dialog.autoPop then
        autoPop = dialog.autoPop
    end
    if type(dialog)=="userdata" then
        dialog = {view=dialog, priority=dialog.priority, swallow=dialog.swallow, enterAnimate=dialog.enterAnimate,
                  exitAnimate=dialog.exitAnimate, autoCloseCallback=dialog.autoCloseCallback}
    end
    if _dialogDepth>0 then
        local pri = dialog.priority or 1
        display.closeDialog(pri, true)
    end
    _dialogDepth = _dialogDepth+1
    _dialogs[_dialogDepth] = dialog
    dialog.autoPop = autoPop
    dialog.fullscreen = fullscreen
    dialog.deleted = false
    if not dialog.baseScale then
        dialog.baseScale = dialog.view:getScaleX()
    end
    local needRelease = false
    local dback, dark = dialog.dback,dialog.dark
    if not dback and not dark then
        if not dialog.swallow then
            dback = ui.button(_winSize, display.autoPopDialog, {cp1=dialog, priority=-1-_dialogDepth, actionType=0})
            dark = ui.layer(_winSize, GConst.Color.Black)
            dialog.dark = dark
            dback:addChild(dark,-1)
            Event.sendEvent(Event.EventDialogOpen, true)
        else
            dback = ui.touchNode(_winSize, -1-_dialogDepth, false)
        end
        dialog.dback = dback
        dback:addChild(dialog.view)
        dback:setGroupMode(true)
    else
        needRelease = true
    end
    --dump({dback:getContentSize(),dialog.dark},"dback")

    local t = 0
    if dialog.enterAnimate then
        t = dialog:enterAnimate()
    elseif not fullscreen then
        t = 0.15
        local ts = dialog.baseScale
        dialog.view:setScale(ts)
        dialog.view:setOpacity(0)
        dialog.view:runAction(ui.action.fadeIn(t))
        dialog.view:runAction(ui.action.sequence({{"scaleTo",t/2,ts*1.05,ts*1.05},
                                                  {"scaleTo",t/2,ts*0.95,ts*0.95},
                                                  {"scaleTo",t/3,ts,ts}}))
    end
    if dark then
        opPct = opPct or dialog.bgAlpha or 150
        if t>0 then
            dark:setOpacity(0)
            dark:runAction(ui.action.fadeTo(t, opPct))
        else
            dark:setOpacity(opPct)
        end
    end
    -- 如果是alert则把zorder加得无限高
    if dialog.isAlert then
        _baseScene:addChild(dback, 5000)
        dback:setTouchPriority(-200)
    else
        _baseScene:addChild(dback, 1+_dialogDepth)
    end
    if needRelease then
        dback:release()
    elseif dialog.viewDidLoad then
        dialog:viewDidLoad()
    end
end


function display.autoPopDialog(dialog)
    if dialog.autoPop and not dialog.deleted then
        if dialog.autoCloseCallback then
            dialog.autoCloseCallback()
        end
        display.closeDialog(dialog.priority or 1)
    end
end

function display.setNodeTouchRemove(dialog,nodeName)
    if dialog.nodeTouchRemoveBut then
        dialog.nodeTouchRemoveBut:removeFromParent(true)
        dialog.nodeTouchRemoveBut=nil
    end
    local bt=ui.button(dialog.dialogSize, display.removeNode, {cp1=dialog,cp2=nodeName,priority=1, actionType=0})
    display.adapt(bt,0,0,GConst.Anchor.LeftBottom)
    dialog:addChild(bt)
    dialog.nodeTouchRemoveBut=bt
end

function display.removeNode(dialog,nodeName)
    if dialog[nodeName] then
        dialog[nodeName]:removeFromParent(true)
        dialog[nodeName]=nil
    end
end

function display.getDialogPri()
    local depth = _dialogDepth
    while(depth>0)
    do
        if _dialogs[depth] then
            _dialogDepth = depth
            return	_dialogs[depth].priority or 1
        end
        depth = depth - 1
    end
    return 0
end

local function _popNotice(label)
    local rmId = nil
    for i, notice in pairs(_notices) do
        if label==notice then
            rmId = i
            label:removeFromParent(true)
        end
    end
    if rmId then _notices[rmId] = nil end
end

-- function display.pushNotice(text,params)
--     local setting=params or {yRate = 0.5}
--     local delayTime = 3
--     local outTime = 1
--     local disy = 10
--     local color = setting.color
--     if not color then
--         color = GConst.Color.Red--默认红色字
--     end
--     local scale = ui.getUIScale2()
--     local nscale = ui.getUIScale()

--     local label = ui.label(text, setting.fontName or General.font1,
--                                  (setting.fontSize or 25)*nscale, {width=1000, color=color})

--     display.adapt(label, 0, display.winSize[2]*0.5*(setting.yRate or 0.5),
--                                  GConst.Anchor.Top, {datum=GConst.Anchor.Center})
--     local bscale = label:getScaleY()
--     local my = label:getContentSize().height * bscale
--     my = my*scale
--     bscale = bscale*scale
--     label:setOpacity(1)
--     _baseScene:addChild(label, 10000)

--     -- dump({
--     --     my = my,
--     --     bscale = bscale,
--     --     scale = scale,
--     --     yRate = setting.yRate,
--     --     disy = disy,
--     --     yPos = display.winSize[2]*0.5*(setting.yRate or 0.5)
--     --     })

--     label:runAction(ui.action.sequence({{"spawn",{{"fadeTo",0.1,255},{"moveBy",0.1,0,disy+my}}}}))
--     label:runAction(ui.action.sequence({{"delay",delayTime},{"fadeOut",outTime},{"call",Handler(_popNotice,label)}}))
--     for _, _label in pairs(_notices) do
--         --_label:setPositionY(label:getPositionY()+disy+my)
--         --_label:runAction(ui.action.sequence({{"moveBy",0.1,0,disy+my},"remove"}))
--         _label:removeFromParent()
--     end
--     table_clear(_notices)

--     if setting.withAni then
--         label:setScale(0.5*bscale)
--         label:runAction(ui.action.easeSineIO(ui.action.sequence({{"scaleTo",0.3,2*bscale,2*bscale},
--                                                                  {"scaleTo",0.2,bscale,bscale}})))
--     end
--     table.insert(_notices,label)
-- end

function display.pushNotice(text,params)
    local setting=params or {}
    local delayTime = 3
    local outTime = 1
    local disy = 10
    local color = setting.color
    if not color then
        color = GConst.Color.Red--默认红色字
    end
    local label = ui.label(text, setting.fontName or General.font1, setting.fontSize or 30, {width=750, color=color})
    local scale = ui.getUIScale()
    local bscale = label:getScaleY()
    local my = label:getContentSize().height * bscale
    display.adapt(label, 0, my/2-180, GConst.Anchor.Center, {datum=GConst.Anchor.Top, scale=scale})
    my = my*scale
    bscale = bscale*scale
    _baseScene:addChild(label, 10)
    label:runAction(ui.action.sequence({{"delay",delayTime},{"fadeOut",outTime},{"call",Handler(_popNotice,label)}}))
    for _, label in pairs(_notices) do
        label:setPositionY(label:getPositionY()+disy+my)
    end
    if setting.withAni then
        label:setScale(0.5*bscale)
        label:runAction(ui.action.easeSineIO(ui.action.sequence({{"scaleTo",0.3,2*bscale,2*bscale},{"scaleTo",0.2,bscale,bscale}})))
    end
    table.insert(_notices,label)
end

local _notices2 = {}
local function _popNotice2(label)
    local rmId = nil
    for i, notice in pairs(_notices2) do
        if label==notice then
            rmId = i
            label:removeFromParent(true)
        end
    end
    if rmId then _notices2[rmId] = nil end
end
function display.pushGuide(text,params)
    local setting=params or {}
    local delayTime = 1000000
    local outTime = 1
    local disy = 10
    local color = setting.color
    if not color then
        color = {255,255,0}--默认黄色字
    end
    local label = ui.label(text, setting.fontName or General.font1, setting.fontSize or 30, {width=750, color=color})
    local scale = ui.getUIScale()
    display.adapt(label, 0, 280, GConst.Anchor.Bottom, {datum=GConst.Anchor.Bottom, scale=scale})
    _baseScene:addChild(label, 10)
    local my = label:getContentSize().height * label:getScaleY()
    label:runAction(ui.action.sequence({{"delay",delayTime},{"fadeOut",outTime},{"call",Handler(_popNotice2,label)}}))
    for _, _label in pairs(_notices) do
        _label:setPositionY(label:getPositionY()+disy+my)
    end
    table.insert(_notices2,label)
end
function display.removeGuide()
    while _notices2[1] do
        local label = _notices2[1]
        label:removeFromParent(true)
        table.remove(_notices2,1)
    end
end

function display.getBaseScene()

    return _baseScene
end

function display.getDepth()
    return clone(_dialogDepth)
end

-- 仿android的一种实现方案
function display.sendIntent(intent)
    if not intent then
        return
    end
    local intentType = intent.type or "dialog"
    if intentType == "dialog" then
        local className = intent.class
        local params = intent.params
        local newDialogClass = GMethod.loadScript(className)
        local newDialog = newDialogClass.new(params)
        newDialog.__intent = intent
        if not intent.autoShowed then
            display.showDialog(newDialog, intent.autoPop or newDialog._autoPop or false)
        end
    end
end

-- 保存当前可存储的栈
function display.pushStack()
    local stacks = {}
    for i = 1, _dialogDepth do
        local dialog = _dialogs[i]
        if dialog and dialog.__intent and dialog.saveIntent then
            local intent = dialog:saveIntent(dialog.__intent)
            if intent then
                table.insert(stacks, intent)
            end
        end
    end
    display._dialogTempStacks = stacks
    dump(stacks,"pushStack stacks",1)
end
function display.clearStack()
    display._dialogTempStacks = nil
end
function display.popStack()
    local stacks = display._dialogTempStacks
    display.clearStack()
    -- 恢复之前的界面
    if stacks and #stacks > 0 then
        for _, intent in ipairs(stacks) do
            display.sendIntent(intent)
        end
        return true
    end
    return false
end

function display.saveResidentDialog(dialog)
    print("saveResidentDialog dialog",dialog.priority)
    if _dialogs[dialog.priority] then
        _residentDialog = _dialogs[dialog.priority]
        _residentDialog.resident = true
    end
end

function display.showResidentDialog()
    if _residentDialog then
        print("showResidentDialog dialog",_residentDialog.priority)
        display.showDialog(_residentDialog)
        _residentDialog:loadViewsTo()
        _residentDialog.resident = false
        _residentDialog = nil
    end
end

return display
