local const = GMethod.loadScript("game.GameLogic.Const")

RewardDialog = class(DialogViewLayout)

--根据奖励数量决定打开方式
function RewardDialog:onInitDialog()
    self:setLayout("RewardDialog.json")
    local rewards = self.rewards
    if KTLen(rewards)==1 then
        self:addLayout("SingleReward")
        self:loadViewsTo()

        local bg = self.nodeItemBack.view
        local p = ui.sprite("images/dialogs/beijingguang.png")
        display.adapt(p, 0, 0, GConst.Anchor.Center)
        bg:addChild(p,-2)
        p:setScale(3.3)
        p:setOpacity(0)
        p:runAction(ui.action.rotateBy(2,-360))
        p:runAction(ui.action.fadeIn(0.4))
        ui.setBlend(p, 770, 1)

        p = GameUI.addItemIcon(bg, rewards[1][1], rewards[1][2], 1, 0, 0, true)
        p:setOpacity(0)
        p:runAction(ui.action.fadeIn(0.4))
        GameUI.setItemName(self.labelRewardName,rewards[1][1], rewards[1][2],rewards[1][3])

        p = ui.sprite("images/dialogs/vk1.png")
        p:setAnchorPoint(1,0.5)
        p:setPosition(-1024,0)
        bg:addChild(p,100)

        p:setScale(6.6)
        p:setOpacity(0)
        p:runAction(ui.action.sequence({{"scaleTo",0.2,3,0.75},{"scaleTo",0.1,0.83,0.5}}))
        p:runAction(ui.action.fadeIn(0.2))
        p:runAction(ui.action.moveTo(0.3,-94,0))
        ui.setBlend(p, 770, 1)

        p = ui.sprite("images/dialogs/vk1.png")
        p:setAnchorPoint(1,0.5)
        p:setPosition(1024,0)
        bg:addChild(p,100)
        p:setRotation(180)
        p:setScale(6.6)
        p:setOpacity(0)
        p:runAction(ui.action.sequence({{"scaleTo",0.2,3,0.75},{"scaleTo",0.1,0.83,0.5}}))
        p:runAction(ui.action.fadeIn(0.2))
        p:runAction(ui.action.moveTo(0.3,94,0))
        ui.setBlend(p, 770, 1)

        p = ui.sprite("images/dialogs/vk1.png")
        p:setAnchorPoint(1,0.5)
        p:setPosition(0,768)
        bg:addChild(p,100)
        p:setRotation(90)
        p:setScale(6.6)
        p:setOpacity(0)
        p:runAction(ui.action.sequence({{"scaleTo",0.2,3,0.75},{"scaleTo",0.1,0.83,0.5}}))
        p:runAction(ui.action.fadeIn(0.2))
        p:runAction(ui.action.moveTo(0.3,0,94))
        ui.setBlend(p, 770, 1)

        p = ui.sprite("images/dialogs/vk1.png")
        p:setAnchorPoint(1,0.5)
        p:setPosition(0,-768)
        bg:addChild(p,100)
        p:setRotation(-90)
        p:setScale(6.6)
        p:setOpacity(0)
        p:runAction(ui.action.sequence({{"scaleTo",0.2,3,0.75},{"scaleTo",0.1,0.83,0.5}}))
        p:runAction(ui.action.fadeIn(0.2))
        p:runAction(ui.action.moveTo(0.3,0,-94))
        ui.setBlend(p, 770, 1)

        p = ui.sprite("images/dialogs/shanshan.png")
        p:setAnchorPoint(125/256,0.5)
        p:setPosition(0,0)
        bg:addChild(p,100)
        p:setScale(2.86)
        p:setOpacity(0)
        p:runAction(ui.action.arepeat(ui.action.rotateBy(2,360)))
        p:runAction(ui.action.fadeIn(0.4))
        p:setColor(cc.c3b(255,166,0))
        ui.setBlend(p, 770, 1)

        p = ui.particle("images/dialogs/baowu.plist")
        p:setScale(1.1)
        p:setPosition(0,0)
        p:setPositionType(cc.POSITION_TYPE_GROUPED)
        bg:addChild(p, 100)

        self.btnBackground:setScriptCallback(ButtonHandler(display.closeDialog, 0))

        music.play("sounds/mrxbReward.wav")
    else
        self:addLayout("MultiReward")
        self:loadViewsTo()
        self.btnSure:setScriptCallback(ButtonHandler(self.onNextPage, self))
        self:onNextPage()
    end
end

function RewardDialog:onNextPage()
    if self.finished then
        display.closeDialog(self.priority)
        return
    end
    local page = (self.page or 0)+1
    self.page=page
    local infos = {}
    for i=(page-1)*15+1, page*15 do
        local reward = self.rewards[i]
        if reward then
            table.insert(infos, {itemtype=reward[1], itemid=reward[2], itemnum=reward[3]})
        else
            break
        end
    end
    if not self.rewards[page*15+1] then
        self.finished = true
        self.btnSureWord:setString(Localize("btnYes"))
    else
        self.btnSureWord:setString(Localize("stirngNextPade"))
    end
    self.nodeRewardTable:loadTableView(infos, Handler(self.updateRewardCell, self))
end

function RewardDialog:updateRewardCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    if not info.cell then
        info.cell = cell
        cell:setEnable(false)
        info.viewLayout = self:addLayout("RewardCell", bg)
        info.viewLayout:loadViewsTo(info)
    end
    info.nodeItemBack:removeAllChildren(true)
    GameUI.addItemIcon(info.nodeItemBack.view,info.itemtype,info.itemid,1,0,0,true)
    GameUI.setItemName(info.labelNum,info.itemtype,info.itemid,info.itemnum)
end
