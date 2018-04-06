local UI = {}
local _t_unpack = table.unpack or unpack

do
    --因为lua和C之间的交互较慢，考虑使用更合理的方式进行复用
    local _reusingSprites = {}
    local _reusingSpriteNum = 0
    local _reuseSprites = {}
    local _reuseSpriteNum = 0
    local _reuseFrames = {}

    local _reusingParticles = {}
    local _reusingParticleNum = 0
    local _reuseParticles = {}
    local _reuseParticleNum = 0

    local function reuseFrame(frameName)
        local frame = _reuseFrames[frameName]
        if frame == nil then
            frame = memory.getFrame(frameName)
            _reuseFrames[frameName] = frame or false
        end
        return frame
    end

    local function clearReuseFrame()
        _reuseFrames = {}
    end

    local function reuseSprite(frameName, size)
        local sprite
        local frame = reuseFrame(frameName)
        if not frame then
            if buglyLog then
                buglyLog(2, "ImagePath", frameName)
            else
                print("wtf?", frameName)
            end
            return
        end
        if _reuseSpriteNum > 0 then
            sprite = _reuseSprites[_reuseSpriteNum]
            _reuseSprites[_reuseSpriteNum] = nil
            _reuseSpriteNum = _reuseSpriteNum - 1

            sprite:setSpriteFrame(frame)
        else
            sprite = CaeSprite:createWithSpriteFrame(frame)
            sprite:retain()
        end
        _reusingSpriteNum = _reusingSpriteNum + 1
        _reusingSprites[_reusingSpriteNum] = sprite
        if size then
            sprite:setScaleContentSize(size[1], size[2], false)
        end
        return sprite
    end

    local function reuseParticle(confFile, otherSetting)
        local num, duration = 0, 0
        if otherSetting then
            num = otherSetting.max or 0
            duration = otherSetting.d or 0
        end
        local node
        if _reuseParticleNum > 0 then
            node = _reuseParticles[_reuseParticleNum]
            _reuseParticles[_reuseParticleNum] = nil
            _reuseParticleNum = _reuseParticleNum - 1

            node:initWithJson(confFile, num, duration)
        else
            node = CaeParticleNode:createWithJson(confFile, num, duration)
            node:retain()
        end
        _reusingParticleNum = _reusingParticleNum + 1
        _reusingParticles[_reusingParticleNum] = node
        return node
    end

    local function updateReuses()
        local idx
        idx = 1
        while idx <= _reusingSpriteNum do
            if _reusingSprites[idx]:getReferenceCount() == 1 then
                _reuseSpriteNum = _reuseSpriteNum + 1
                _reuseSprites[_reuseSpriteNum] = _reusingSprites[idx]
                _reusingSprites[idx]:clearDatas()

                _reusingSprites[idx] = _reusingSprites[_reusingSpriteNum]
                _reusingSprites[_reusingSpriteNum] = nil
                _reusingSpriteNum = _reusingSpriteNum - 1

            else
                idx = idx + 1
            end
        end

        idx = 1
        while idx <= _reusingParticleNum do
            if _reusingParticles[idx]:getReferenceCount() == 1 then
                _reuseParticleNum = _reuseParticleNum + 1
                _reuseParticles[_reuseParticleNum] = _reuseParticles[idx]
                --_reuseParticles[idx]:clearDatas()

                _reusingParticles[idx] = _reusingParticles[_reusingParticleNum]
                _reusingParticles[_reusingParticleNum] = nil
                _reusingParticleNum = _reusingParticleNum - 1
            else
                idx = idx + 1
            end
        end
    end

    UI.reuseFrame = reuseFrame
    UI.reuseSprite = reuseSprite
    UI.reuseParticle = reuseParticle
    UI.clearReuseFrame = clearReuseFrame
    UI.updateReuses = updateReuses
end

-- local spool = MemoryPool:getInstance()

function UI.node(size)
    local node = cc.Node:create()
    -- local node = spool:createNode()
    node:setCascadeOpacityEnabled(true)
    if size then
        node:setContentSize(size[1],size[2])
    end
    return node
end

function UI.layer(size, color)
    local layer
    if color then
        layer = cc.LayerColor:create(cc.c4b(color[1],color[2],color[3],color[4] or 255),size[1],size[2])
        layer:setCascadeOpacityEnabled(true)
    else
        layer = cc.Layer:create()
    end
    return layer
end

function UI.shlNode(size)
    local node
    node = CaeHSLNodeRGBA:create()
    if size then
        node:setContentSize(size[1],size[2])
    end
    return node
end

function UI.colorNode(size, color)
    local node
    node = CaeShaderNode:create("grid", cc.size(size[1],size[2]))
    node:setCascadeOpacityEnabled(true)
    node:setCascadeColorEnabled(true)
    node:setColor(cc.c3b(color[1],color[2],color[3]))
    if color[4] then
        node:setOpacity(color[4])
    end
    return node
end

function UI.clippingNode(size, ccnode)
    local cnode
    if ccnode then
        cnode = cc.ClippingNode:create(ccnode)
        cnode:setAlphaThreshold(0.1)
        cnode:setInverted(false)
    else
        cnode = cc.ClippingRectangleNode:create(cc.rect(0, 0, size[1], size[2]))
    end
    cnode:setCascadeOpacityEnabled(true)
    if size then
        cnode:setContentSize(size[1], size[2])
    end
    return cnode
end

function UI.touchNode(size, priority, hold)
    if hold==nil then
        hold = true
    end
    local node = TouchNode:create(priority, hold)
    node:setContentSize(size[1],size[2])
    return node
end

function UI.scrollNode(size, pri, sx, sy, settings)
    local scrollNode = ScrollNode:create(cc.size(size[1],size[2]), pri, sx, sy)
    if settings then
        if settings.scroll then
            scrollNode:setScrollEnable(true)
        end
        if settings.inertia then
            scrollNode:setInertia(true)
        end
        if settings.elastic then
            scrollNode:setElastic(true)
        end
        if settings.clip then
            scrollNode:setClip(true)
        end
        if settings.scale then
            scrollNode:setScaleEnable(true, _t_unpack(settings.scale))
        end
        if settings.rect then
            scrollNode:setScrollContentRect(cc.rect(_t_unpack(settings.rect)))
        end
    end
    return scrollNode
end

--先兼容当前；目标要去除size参数，因为可更换性差。
function UI.sprite(filename, size, keepScale, lazyLoad)
    --print("----------------------------------------------------------------------filename",filename)
    local sprite
    local frame = memory.getFrame(filename,true)
    if not frame then
        sprite = CaeSprite:create(filename, lazyLoad)
    else
        sprite = CaeSprite:createWithSpriteFrame(frame)
    end

    if sprite and size then
        sprite:setScaleContentSize(size[1],size[2],(keepScale==true))
    end
    if not sprite then
        log.d(debug.traceback())
        print("not image:",filename)
    end
    if not sprite then
        -- dump(filename)
        -- display.pushNotice(filename)
        sprite = CaeSprite:create("UIImages/bt/btn_breakHero_checkFrame.png")
    end
    return sprite
end

--先兼容当前；目标要去除size参数，因为可更换性差。
function UI.spriteOld(filename, size, keepScale, lazyLoad)
    -- local frameName
    -- local sprite = nil
    -- if filename:find("images/") then
    --     frameName = string.sub(filename, 8)
    -- else
    --     frameName = filename
    -- end
    -- local frame = memory.getFrame(frameName)
    -- if not frame then
    --     sprite = CaeSprite:create(filename)
    -- else
    --     sprite = CaeSprite:createWithSpriteFrame(frame)
    -- end
    local sprite = CaeSprite:create(filename, lazyLoad)
    if sprite and size then
        sprite:setScaleContentSize(size[1], size[2], keepScale==true)
    end
    if not sprite then
        -- log.e(debug.traceback())
        if buglyLog then
            buglyLog(2, "ImagePath", filename)
        else
            print("not image:",filename)
        end
    end
    return sprite
end

--将大图切成等份m*n的块，再拼起来
function UI.spriteBlock(filename, size, mn, keepScale, lazyLoad)
    local name=string.sub(filename, 1, string.len(filename)-4)
    local blockNumer=0
    local m,n=mn[1],mn[2]
    local node =ui.node({size[1],size[2]})
    local childSize = {size[1]/m, size[2]/n}
    for i=n,1,-1 do
        for j=1,m do
            blockNumer=blockNumer+1
            local x=(j-1)*childSize[1]
            local y=(i-1)*childSize[2]
            local sprite = ui.sprite(name .. "_" .. blockNumer .. ".png", childSize, keepScale, lazyLoad)
            display.adapt(sprite,x,y,GConst.Anchor.LeftBottom)
            node:addChild(sprite)
        end
    end
    return node
end

function UI.batch(filename, num)
    local frameName
    local batch = nil
    if filename:find("images/") then
        frameName = string.sub(filename, 8)
    else
        frameName = filename
    end
    local frame = memory.getFrame(frameName, true)
    if num and num>0 then
        if not frame then
            batch = CaeSpriteBatchNode:create(filename, num)
        else
            batch = CaeSpriteBatchNode:createWithTexture(frame:getTexture(), num)
        end
    else
        if not frame then
            batch = CaeSpriteBatchNode:create(filename)
        else
            batch = CaeSpriteBatchNode:createWithTexture(frame:getTexture())
        end
    end
    return batch
end

function UI.scale9(filename, edge, size)
    local sprite = UI.sprite(filename)
    -- local sprite = spool:createSprite(filename)
    if not sprite then
        if buglyLog then
            buglyLog(2, "ImagePath", filename)
        else
            print("not image", filename)
        end
    end
    if type(edge) == "number" then
        sprite:setScale9mode(edge)
    else
        sprite:setScale9mode(edge[1], edge[2], edge[3], edge[4])
    end
    sprite:setContentSize(cc.size(size[1], size[2]))
    return sprite
end

function UI.animate2(duration, prefix, frameNum, setting)
    local params = setting or {}
    local suffix = params.suffix or ".png"
    local beginNum = params.beginNum or 0
    local rollback = params.isRollback
    local animation = cc.Animation:create()
    if type(frameNum)=="table" then
        for _, i in ipairs(frameNum) do
            animation:addSpriteFrameWithFileName(prefix .. i .. suffix)
        end
        animation:setDelayPerUnit(duration/#frameNum)
        animation:setRestoreOriginalFrame(false)
    else
        for i = beginNum, beginNum+frameNum-1 do
            animation:addSpriteFrameWithFileName(prefix .. i .. suffix)
        end
        if rollback then
            for i = beginNum+frameNum-2, beginNum+1, -1 do
                animation:addSpriteFrameWithFileName(prefix .. i .. suffix)
            end
            animation:setDelayPerUnit(duration/(2*frameNum-2))
            animation:setRestoreOriginalFrame(true)
        else
            animation:setDelayPerUnit(duration/frameNum)
            animation:setRestoreOriginalFrame(false)
        end
    end
    local animate = cc.Animate:create(animation)
    return animate
end

--setting:suffix 后缀 beginNum isRollback plist
function UI.animate(duration, prefix, frameNum, setting)
    local params = setting or {}
    local suffix = params.suffix or ".png"
    local beginNum = params.beginNum or 0
    local rollback = params.isRollback
    local frame = memory.getFrame(prefix .. beginNum .. suffix, true)
    if not frame then
        memory.loadSpriteSheet(params.plist)
    end
    local animation = cc.Animation:create()
    if type(frameNum)=="table" then
        for _, i in ipairs(frameNum) do
            animation:addSpriteFrame(memory.getFrame(prefix .. i .. suffix))
        end
        animation:setDelayPerUnit(duration/#frameNum)
        animation:setRestoreOriginalFrame(false)
    else
        for i = beginNum, beginNum+frameNum-1 do
            animation:addSpriteFrame(memory.getFrame(prefix .. i .. suffix))
            --print("ui.animate",prefix..i..suffix)
        end
        if rollback then
            for i = beginNum+frameNum-2, beginNum+1, -1 do
                animation:addSpriteFrame(memory.getFrame(prefix .. i .. suffix))
            end
            animation:setDelayPerUnit(duration/(2*frameNum-2))
            animation:setRestoreOriginalFrame(true)
        else
            animation:setDelayPerUnit(duration/frameNum)
            animation:setRestoreOriginalFrame(false)
        end
    end
    local animate = cc.Animate:create(animation)
    return animate
end

--setting:suffix beginNum isRollback plist isRepeat autoRemove
--wrj_1_a_4_0.png
function UI.animateSprite(duration, prefix, frameNum, setting)
    --print("----------------ui.animateSprite",prefix..setting.beginNum..".png")
    local animate = UI.animate(duration, prefix, frameNum, setting)
    local sprite = UI.sprite(prefix .. (setting and setting.beginNum or 0) .. ".png")
    if setting and setting.isRepeat then
        sprite:runAction(cc.RepeatForever:create(animate))
    elseif setting.autoRemove then
        sprite:runAction(cc.Sequence:create({animate,ActionRemove:create()}))
    elseif setting.callFunc then
        sprite:runAction(cc.Sequence:create({animate,setting.callFunc}))
    else
        sprite:runAction(animate)
    end
    if not sprite then
        print("not prefix",prefix)
    end
    return sprite,animate
end

function UI.textBox(size, text, fontId, fontSize, setting)
    local fnames = string.split(setting.back, "/")
    local fnameNum = #fnames
    local fname
    local frame = nil
    for i=fnameNum, 1, -1 do
        if i == fnameNum then
            fname = fnames[i]
        else
            fname = fnames[i] .. "/" .. fname
        end
        frame = memory.getFrame(fname, true)
        if frame then
            break
        end
    end
    local textBox = ccui.EditBox:create(cc.size(size[1], size[2]), fname, frame and 1 or 0)
    local caeFont = CaeLabelFont:getFont(fontId)
    if not caeFont then
        log.e(debug.traceback())
        log.e("Error in use label font:" .. fontId.."   use font1 for now")
        caeFont = CaeLabelFont:getFont(1)
    end
    textBox:setFont(caeFont:getFontName(), fontSize)
    textBox:setPlaceholderFont(caeFont:getFontName(), fontSize)
    if setting.color then
        textBox:setFontColor(cc.c4b(setting.color[1], setting.color[2], setting.color[3], setting.color[4] or 255))
    else
        textBox:setFontColor(cc.c4b(0, 0, 0, 255))
    end
    if setting.placeHolderColor then
        local cl = setting.placeHolderColor
        textBox:setPlaceholderFontColor(cc.c4b(cl[1], cl[2], cl[3], cl[4] or 255))
    else
        textBox:setPlaceholderFontColor(cc.c4b(100, 100, 100, 255))
    end
    local iosPlatform = json.decode(Native:getDeviceInfo()).platform == "ios"
    if setting.mode and setting.mode==6 and iosPlatform then
        setting.mode = nil
    end
    textBox:setInputMode(setting.mode or 0)
    textBox:setMaxLength(setting.max or 200)
    textBox:setInputFlag(setting.flag or 5)
    textBox:setReturnType(setting.returnType or 0)
    textBox:setPlaceHolder(text)
    if setting.text then
        textBox:setText(setting.text)
    end
    local function showTouch()
        textBox:touchDownAction(textBox, 2)
    end
    textBox:setTouchEnabled(false)
    local touchBut = UI.button(size, showTouch, {sound=false})
    display.adapt(touchBut, 0, 0, GConst.Anchor.LeftBottom)
    textBox:addChild(touchBut, -1)


    local call = setting.callback
    local function txtCall(eventname,sender)
        if eventname == "began" then
            if call.txtBegan then
                call.txtBegan(sender)
            end
        elseif eventname == "ended" then
            -- 当编辑框失去焦点并且键盘消失的时候被调用
            if call.txtEnded then
                call.txtEnded(sender)
            end
        elseif eventname == "return" then
            -- 当用户点击编辑框的键盘以外的区域，或者键盘的Return按钮被点击时所调用
            if call.txtReturn then
                call.txtReturn(sender)
            end
        elseif eventname == "changed" then
            -- 输入内容改变时调用
            if call.txtChanged then
                call.txtChanged(sender)
            end
        end
    end
    if call then
        textBox:registerScriptEditBoxHandler(txtCall)
    end

    return textBox
end

function UI.label(text, fontName, fontSize, setting)
    if text  then
        text = string.gsub(tostring(text), "(.-)%s*$", "%1")
    end
    local params = setting or {}
    local width = params.width or 0
    local align = params.align or GConst.Align.Center
    local valign = params.valign or 1
    local color = params.color or GConst.Color.White
    local outColor = params.outColor
    if type(fontName) ~= "number" then
        log.e(debug.traceback())
        log.e("Error in use label:" .. fontName)
        fontName = 1
    end
    local label
    local caeFont = CaeLabelFont:getFont(fontName)
    if not caeFont then
        log.e(debug.traceback())
        log.e("Error in use label font:" .. fontName.."   use font1 for now")
        caeFont = CaeLabelFont:getFont(1)
    end
    local height = params.height or 0
    if params.fontW and params.fontH then
        height = params.fontH
        width = params.fontW or width
    end
    label = CaeLabel:createWithFont(text, caeFont, fontSize, cc.size(width, height), align)
    if height > 0 then
        label:setOverflow(2)
    else
        label:setOverflow(3)
    end
    if caeFont:getFontName():find(".ttf") then
        if params.lh then
            label:setLineHeight(params.lh)
        else
            label:setLineHeight(fontSize + 4)
        end
    end

    label:setTextColor(cc.c3b(color[1],color[2],color[3]))
    if outColor then
        label:setOutlineColor(cc.c4b(outColor[1],outColor[2],outColor[3],outColor[4] or 255))
    end

    return label
end

function UI.scrollLabel(text, fontName, fontSize, setting)
    local ScrollLabel=require "engine.ScrollLabel"
    local label=ScrollLabel.new(text, fontName, fontSize, setting)
    return label
end

function UI.getUIScale()
    return UI.normalScale
end

function UI.getUIScale2()
    return UI.normalScale/2
end

function UI.button(size, callback, params)
    local but = ButtonNode:create(cc.size(size[1],size[2]), params.priority or 0, params.actionType or 1)
    if params.anchor then
        but:setDrawAnchor(params.anchor[1], params.anchor[2])
    end
    if params.image then
        if params.scale9edge and type(params.scale9edge) == "table" then
            local tmp = UI.scale9(params.image, params.scale9edge, size)
            display.adapt(tmp, 0, 0)
            but:getDrawNode():addChild(tmp, -1)
        else
            but:setBackgroundImage(params.image, params.scale9edge or 0)
        end
    end
    if callback and callback~=GMethod.doNothing then
        but:setScriptCallback(Script.createCallbackHandler(callback, params.cp1, params.cp2))
    end
    if params.more then
        local temp
        for _, mitem in ipairs(params.more) do
            if mitem[1]=="image" then
                temp = UI.sprite(mitem[2], {mitem[3],mitem[4]})
                display.adapt(temp, size[1]/2+mitem[5], size[2]/2+mitem[6], GConst.Anchor.Center)
            elseif mitem[1]=="label" then
                 -- print("-------------create label begin")
                temp = UI.label(mitem[2], mitem[3], mitem[4], mitem[5])
                display.adapt(temp, size[1]/2+mitem[6], size[2]/2+mitem[7], GConst.Anchor.Center)
            end
            but:getDrawNode():addChild(temp)
        end
    end
    if params.inScroll then
        but:setTouchThrowProperty(true, true)
    end
    --lee 添加的
    function but:setListener(fuc)
        self:setScriptCallback(Script.createCallbackHandler(fuc))
    end
    if params.sound==false then
        but:setInitSoundEnable(params.sound)
    end
   return but
end

function UI.testButton(size, callback, params)
    local call = callback or function()
        log.d("点击");
    end;
    local params = params or {};
    params.image = params.image or "UIImages/bt/bt_guideDef.png";
    local btn = ui.button(size, call, params);
    return btn;
end

function UI.setRectAndScale(scrollNode, rect, scale)
    if rect then
        scrollNode:setScrollContentRect(cc.rect(_t_unpack(rect)))
    end
    if scale then
        scrollNode:setScaleEnable(true, _t_unpack(scale))
    else
        scrollNode:setScrollEnable(false, 1, 1, 1, 1)
    end
end

function UI.setBlend(node, src, dst)
    local blend = {}
    if dst then
        blend.src = src
        blend.dst = dst
    else
        blend.src = src[1]
        blend.dst = src[2]
    end
    node:setBlendFunc(blend)
end

function UI.setColor(node, r, g, b)
    if type(r) == "string" then
        local c = {255,255,255}
        if r == "red" then
            r,g,b = 252,58,66
        else
            r,g,b = 255,255,255
        end
    end
    if type(node) == "table" then
        node:setColor(r, g, b)
        return
    end

    if node.setTextColor then
        if not g then
            node:setTextColor(cc.c3b(r[1],r[2],r[3],255))
        else
            node:setTextColor(cc.c3b(r, g, b, 255))
        end
    else
        if not g then
            node:setColor(cc.c3b(r[1],r[2],r[3]))
        else
            node:setColor(cc.c3b(r, g, b))
        end
    end
end

function UI.setFrame(sprite, frameName)
    local fnames = string.split(frameName, "/")
    local fnameNum = #fnames
    local fname
    local frame = nil
    for i=fnameNum, 1, -1 do
        if i == fnameNum then
            fname = fnames[i]
        else
            fname = fnames[i] .. "/" .. fname
        end
        frame = memory.getFrame(fname, true)
        if frame then
            sprite:setSpriteFrame(frame)
            return
        end
    end
    local texture = memory.loadTexture(frameName)
    if texture then
        sprite:setTexture(texture)
        local tsize = texture:getContentSize()
        sprite:setTextureRect(cc.rect(0, 0, tsize.width, tsize.height), false, tsize)
    else
        if buglyLog then
            buglyLog(2, "ImagePath", frameName)
        else
            print("not image", frameName)
        end
    end
end

local Action = {}

function Action.fadeOut(t)
    return cc.FadeOut:create(t)
    -- return spool:createFadeTo(t, 0)
end

function Action.fadeIn(t)
    return cc.FadeIn:create(t)
    -- return spool:createFadeTo(t, 255)
end

function Action.delay(t)
    return cc.DelayTime:create(t)
    -- return spool:createDelay(t)
end

function Action.fadeTo(t, p)
    return cc.FadeTo:create(t, p)
    -- return spool:createFadeTo(t, p)
end

function Action.tintto(t,color)
    return cc.TintTo:create(t, color[1],color[2],color[3])
    -- return spool:createTintTo(t, color[1], color[2], color[3])
end

function Action.scaleTo(t,s1,s2)
    return cc.ScaleTo:create(t,s1,s2)
    -- return spool:createScaleTo(t, s1, s2)
end

function Action.moveTo(t,x,y)
    return cc.MoveTo:create(t,cc.p(x,y))
    -- return spool:createMoveTo(t, cc.vec3(x, y, 0))
end

function Action.moveBy(t,x,y)
    return cc.MoveBy:create(t,cc.p(x,y))
    -- return spool:createMoveBy(t, cc.vec3(x, y, 0))
end

function Action.blink(t, n)
    return cc.Blink:create(t, n)
    -- return spool:createBlink(t, n)
end

function Action.skewBy(t, sx, sy)
    return cc.SkewBy:create(t, sx, sy)
    -- return spool:createSkewBy(t, sx, sy)
end

function Action.rotateBy(t, r)
    return cc.RotateBy:create(t,r)
    -- return spool:createRotateBy(t, r)
end

function Action.rotateTo(t, r)
    return cc.RotateTo:create(t,r)
    -- return spool:createRotateTo(t, r)
end

function Action.bezierBy(t,points)
    local config = {}
    config.controlPoint_1 = cc.p(points[1], points[2])
    config.controlPoint_2 = cc.p(points[3], points[4])
    config.endPosition = cc.p(points[5], points[6])
    return cc.BezierBy:create(t, config)
end

function Action.bezierTo(t,points)
    local config = {}
    config.controlPoint_1 = cc.p(points[1], points[2])
    config.controlPoint_2 = cc.p(points[3], points[4])
    config.endPosition = cc.p(points[5], points[6])
    return cc.BezierTo:create(t, config)
end

function Action.remove(cleanup)
    if cleanup==nil then cleanup=true end
    return ActionRemove:create(cleanup)
    -- return spool:createRemove(cleanup)
end

function Action.hide()
    return cc.Hide:create()
    -- return spool:createHide()
end

function Action.show()
    return cc.Show:create()
    -- return spool:createShow()
end

function Action.call(func)
    return cc.CallFunc:create(func)
end

function Action.easeIn(action, spd)
    return cc.EaseIn:create(Action.action(action), spd)
end

function Action.easeSineIn(action)
    return cc.EaseSineIn:create(Action.action(action))
end

function Action.easeSineOut(action)
    return cc.EaseSineOut:create(Action.action(action))
end

function Action.easeSineIO(action)
    return cc.EaseSineInOut:create(Action.action(action))
end

function Action.easeBackIn(action)
     return cc.EaseBackIn:create(Action.action(action))
end

function Action.easeBackOut(action)
     return cc.EaseBackOut:create(Action.action(action))
end

function Action.easeBackInOut(action)
     return cc.EaseBackInOut:create(Action.action(action))
end

function Action.actionShake(d,ampx,ampy)
    return ActionShake:create(d,ampx,ampy)
    -- return spool:createShake(d,ampx,ampy)
end

Action["repeat"] = function (action, num)
    if num and num>0 then
        return cc.Repeat:create(Action.action(action), num)
    else
        return cc.RepeatForever:create(Action.action(action))
    end
end

Action.arepeat = Action["repeat"]

Action.animate = UI.animate

local _action

function Action.sequence(actions)
    local anum = #actions
    if anum==1 then
        return _action(actions[1])
    else
        local array = {}
        for _,action in ipairs(actions) do
            table.insert(array, _action(action))
        end
        return cc.Sequence:create(array)
    end
end

function Action.spawn(actions)
    local anum = #actions
    if anum==1 then
        return _action(actions[1])
    else
        local array = {}
        for _,action in ipairs(actions) do
            table.insert(array, _action(action))
        end
        return cc.Spawn:create(array)
    end
end

function Action.action(action)
    if type(action)=="table" then
        return Action[action[1]](action[2],action[3],action[4])
    elseif type(action)=="string" then
        return Action[action]()
    else
        return action
    end
end
_action = Action.action
local _sequence = Action.sequence

local _dr_settings = {{"delay",1},"remove"}
function Action.dr(t,n)
    if not t or t<=0 or not n then
        return
    end
    local ds = _dr_settings
    ds[1][2] = t
    n:runAction(_sequence(ds))
end

UI.action = Action

local pcache = {}

local methFS = {}
methFS.__index = function(t, k)
    return t.first[k] or t.second[k]
end

local function createPartiSetting(first, second)
    if not first then
        return second
    end
    if not second then
        return first
    end
    local setting = {first=first, second=second}
    setmetatable(setting, methFS)
    return setting
end

function UI.particle(confFile, otherSetting)
    if GEngine.rawConfig.DEBUG_NOP then
        local p = ui.node()
        function p:setPositionType()

        end
        function p:setBlendFunc()

        end
        function p:setAutoRemoveOnFinish()

        end
        p:runAction(ui.action.sequence({{"delay",5},"remove"}))
        return p
    end
    if confFile:find(".plist") then
        local p = cc.ParticleSystemQuad:create(confFile)
        --p:setAutoRemoveOnFinish(true)
        print("still use old plist", confFile)
        -- p:setGlobalZOrder(3)
        return p
    end
    local num, duration = 0, 0
    if otherSetting then
        num = otherSetting.max or 0
        duration = otherSetting.d or 0
    end
    local p = CaeParticleNode:createWithJson(confFile, num, duration)
    -- p:setGlobalZOrder(3)
    return p
end

local TableView = require("engine.TableView")

function UI.createTableView(size, isX, params,actionType)
    local tableView = TableView.new(size, isX, params.priority,actionType)
    tableView.cellActionType = params.cellActionType or actionType
    tableView:setDatas(params)
    tableView:prepare()
    if params.dismovable then
        tableView.view:setElastic(false)
    end
    return tableView
end

local PageView = require("engine.PageView")

function UI.createPageView(size,page,clomn,row,params,actionType)
    local pageView = PageView.new(size,page,clomn,row,params,actionType)
    if params then
        pageView:setDatas(params)
    end
    return pageView
end

local TabView = require("engine.TabView")

function UI.createTabView(size)
    return TabView.new(size)
end

function UI.setListener(obj,fuc)
    obj:setScriptCallback(Script.createCallbackHandler(fuc))
end

function UI.csbNode(csb)
    --print("------------------------------------------------------------csbNode",csb)
    local node = cc.CSLoader:createNode(csb)
    node:setCascadeOpacityEnabled(true)
    -- dump(node:getPosition())
    return node
end

function UI.csbTimeLine(csb)
    local action = cc.CSLoader:createTimeline(csb)
    return action
end

function UI.simpleCsbEffect(csb,loop,b,endidx,curIdx)
    local node = UI.csbNode(csb)
    local action = UI.csbTimeLine(csb)
    node:runAction(action)
    if endidx~=nil then
        action:gotoFrameAndPlay(b or 0,endidx,curIdx,loop or false)
    else
        action:gotoFrameAndPlay(b or 0,loop or false)
    end
    return node,action
end

function UI.getWorldPos(node)
    --local x,y = node:getPosition()
    --return node:getParent():convertToWorldSpace(ccp(x,y))
    return node:convertToWorldSpace(ccp(0,0))
end

function UI.getNodePos(toNode,fromNodeOrPos)
    local worldPos
    if type(fromNodeOrPos) == "table" then
        worldPos = fromNodeOrPos
    else
        worldPos = UI.getWorldPos(fromNodeOrPos)
    end
    return toNode:convertToNodeSpace(worldPos)
end

return UI
