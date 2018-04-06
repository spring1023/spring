local SData = GMethod.loadScript("data.StaticData")

-- @brief 设置段位图标用
-- @params bg 一定是个ViewNode对象
-- @params stage 段位类型
-- @params level 段位等级
function GameUI.setTMStageIcon(bg, stage, level)
    if bg.__iconStage == stage and bg.__iconLevel == level then
        return
    end
    bg.__iconStage = stage
    bg.__iconLevel = level
    if bg.__icon then
        bg.__icon:removeFromParent(true)
        bg.__icon = nil
    end
    local data = SData.getData("tmStages", stage, level)
    local tmp
    if cc.FileUtils:getInstance():isFileExist(data.stageIcon) then
        tmp = ui.sprite(data.stageIcon)
        tmp:setScale(bg.size[1] / 225)
        display.adapt(tmp, bg.size[1]/2, bg.size[2]/2, GConst.Anchor.Center)
        bg:addChild(tmp)
        bg.__icon = tmp
    elseif buglyReportLuaException then
        buglyReportLuaException("File not exist:" .. data.stageIcon, debug.traceback())
    end
end

function GameUI.setTMRewardBox(bg, boxLv)
    if bg.__icon then
        bg.__icon:removeFromParent(true)
        bg.__icon = nil
    end
    local tmp = ui.sprite("images/matchs/matchBox" .. boxLv .. ".png")
    tmp:setScale(bg.size[1] / 91)
    display.adapt(tmp, bg.size[1]/2, bg.size[2]/2, GConst.Anchor.Center)
    bg:addChild(tmp)
    bg.__icon = tmp
end

-- @brief 设置角
function GameUI.setAngleView(tempView, mode, length)
    local temp
    local _size
    if type(tempView) == "table" then
        temp = tempView.view
        _size = tempView.size
    else
        temp = tempView
        _size = temp:getContentSize()
        _size = {_size.width * temp:getScaleX(), _size.height * temp:getScaleY()}
    end
    local spercent = length/_size[1]
    temp:setCustomModeNumber(5)
    if mode == 1 then
        temp:setCustomPoint(0, 1-spercent, 0.5, 1-spercent, 0.5)
        temp:setCustomPoint(1, 1, 0, 1, 0)
        temp:setCustomPoint(2, 0, 0, 0, 0)
        temp:setCustomPoint(3, 0, 1, 0, 1)
        temp:setCustomPoint(4, 1, 1, 1, 1)
    elseif mode == 2 then
        temp:setCustomPoint(0, spercent, 0.5, spercent, 0.5)
        temp:setCustomPoint(1, 0, 1, 0, 1)
        temp:setCustomPoint(2, 1, 1, 1, 1)
        temp:setCustomPoint(3, 1, 0, 1, 0)
        temp:setCustomPoint(4, 0, 0, 0, 0)
    elseif mode == 3 then
        temp:setCustomPoint(0, 0, 0, 0, 0)
        temp:setCustomPoint(1, 0, 1, 0, 1)
        temp:setCustomPoint(2, 1-spercent, 1, 1-spercent, 1)
        temp:setCustomPoint(3, 1, 0.5, 1, 0.5)
        temp:setCustomPoint(4, 1-spercent, 0, 1-spercent, 0)
    elseif mode == 4 then
        temp:setCustomPoint(0, spercent, 0, spercent, 0)
        temp:setCustomPoint(1, 0, 0.5, 0, 0.5)
        temp:setCustomPoint(2, spercent, 1, spercent, 1)
        temp:setCustomPoint(3, 1, 1, 1, 1)
        temp:setCustomPoint(4, 1, 0, 1, 0)
    end
end

-- @brief 设置数字
function GameUI.setRankNumber(bgNode, rankNum)
    if bgNode.__rankNum == rankNum then
        return
    end
    bgNode:removeAllChildren(true)
    bgNode.__rankNum = rankNum
    local _size
    if type(bgNode) == "table" then
        _size = bgNode.size
    else
        _size = bgNode:getContentSize()
        _size = {_size.width * bgNode:getScaleX(), _size.height * bgNode:getScaleY()}
    end
    local _os = _size[2] / 122
    if rankNum > 3 or rankNum == 0 then
        local _nstr = tostring(rankNum)
        local _ox = 0
        local bg = ui.node()
        local temp
        if _nstr:len() < 4 then
            _os = _os * 1.75
        else
            _os = _os * 1.5
        end
        for i=1, _nstr:len() do
            temp = ui.sprite("images/ranks/number_" .. _nstr:sub(i, i) .. ".png")
            display.adapt(temp, _ox, 0, GConst.Anchor.Left)
            bg:addChild(temp)
            _ox = _ox + temp:getContentSize().width
        end
        bg:setScale(_os)
        display.adapt(bg, _size[1]/2 - _ox*_os/2, _size[2]/2)
        bgNode:addChild(bg)
    else
        local temp
        if rankNum == 1 then
            temp = ui.sprite("images/ranks/gold.png")
        elseif rankNum == 2 then
            temp = ui.sprite("images/ranks/silver.png")
        else
            temp = ui.sprite("images/ranks/copper.png")
        end
        display.adapt(temp, _size[1]/2, _size[2]/2, GConst.Anchor.Center)
        bgNode:addChild(temp)
    end
end

function GameUI.addRedLine(bg, rotateRight)
    local size = bg.size
    local length = math.sqrt(size[1] * size[1] + size[2] * size[2])
    local node = bg.__redLine
    if not node then
        node = ui.colorNode({length, 6}, {255, 0, 0})
        bg:addChild(node)
        bg.__redLine = node
    else
        node:setContentSize(cc.size(length, 6))
    end
    display.adapt(node, size[1]/2, size[2]/2, GConst.Anchor.Center)
    local angle = math.deg(math.atan2(size[2], size[1]))
    if rotateRight then
        node:setRotation(angle)
    else
        node:setRotation(-angle)
    end
end

local function _closeVisitControl(dialog)
    if not dialog then return end
    local child = dialog.__visitControl
    if child and not tolua.isnull(child) then
        local y = child:getPositionY()
        child:removeFromParent(true)
        return y
    end
    return
end

local function _showVisitControl(params)
    local dialog = params[1]
    local tableView = params[2]
    local leftItem = params[3]
    local uinfo = params[4]
    local pos = leftItem.view:convertToWorldSpace(cc.p(leftItem.size[1], leftItem.size[2]/2))
    local pos2 = dialog.view:convertToNodeSpace(pos)

    pos = tableView.view:convertToWorldSpace(cc.p(0, 0))
    local tpos1 = dialog.view:convertToNodeSpace(pos)
    local downLimitH = tpos1.y + 115
    pos = tableView.view:convertToWorldSpace(cc.p(0, tableView.size[2]))
    tpos1 = dialog.view:convertToNodeSpace(pos)
    local upLimitH = tpos1.y - 100
    local cursorH = 0
    if pos2.y < downLimitH then
        cursorH = pos2.y - downLimitH
        pos2.y = downLimitH
    elseif pos2.y > upLimitH then
        cursorH = pos2.y - upLimitH
        pos2.y = upLimitH
    end
    if cursorH > 56 then
        cursorH = 56
    elseif cursorH < -66 then
        cursorH = -66
    end
    local y = _closeVisitControl(dialog)
    if y == pos2.y or uinfo.id == GameLogic.getUserContext().uid then
        return
    end
    local seeNode = ui.button({443,240}, nil, {image =nil,priority=-3, actionType=3})
    display.adapt(seeNode, 60 + pos2.x, pos2.y, GConst.Anchor.Left)
    dialog.view:addChild(seeNode, 100)

    dialog.__visitControl = seeNode

    local tmp
    tmp = ui.sprite("images/unionOperationBackTriangle.png", {46, 188})
    display.adapt(tmp, -41, 120+cursorH, GConst.Anchor.Left)
    seeNode:addChild(tmp)
    tmp = ui.sprite("images/unionOperationBack.png", {443, 220})
    display.adapt(tmp, 0, 0)
    seeNode:addChild(tmp)
    tmp = ui.label(uinfo.name, General.font6, 40, {color=GConst.Color.Black})
    display.adapt(tmp, 210, 176, GConst.Anchor.Center)
    seeNode:addChild(tmp)
    tmp = ui.button({272, 106}, GameEvent.sendEvent, {image="images/btnGreen.png",
        more={{"label", Localize("btnVisit"), General.font1, 40, nil, 0, 7}},
        cp1 = GameEvent.EventVisitBegin,
        cp2 = {type=const.VisitTypeUn, uid = uinfo.id}
    })
    display.adapt(tmp, 210, 86, GConst.Anchor.Center)
    seeNode:addChild(tmp)
end

-- @brief 访问按钮
function GameUI.registerVisitButton(button, dialog, tableView, leftItem, uinfo)
    button:setScriptCallback(ButtonHandler(_showVisitControl, {dialog, tableView, leftItem, uinfo}))
end

function GameUI.registerVisitBack(dialog, tableView)
    tableView:setScrollCallback(Handler(_closeVisitControl, dialog))
    if not dialog.__hideVisitButton then
        local tmp = ui.button(dialog.size, _closeVisitControl, {cp1=dialog, priority=1})
        display.adapt(tmp, 0, 0)
        dialog.view:addChild(tmp, -1)
        dialog.__hideVisitButton = tmp
    end
end
