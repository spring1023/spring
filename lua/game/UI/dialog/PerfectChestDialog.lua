
local const = GMethod.loadScript("game.GameLogic.Const")
local SD = GMethod.loadScript("data.StaticData").getData
--完美通关宝箱对话框
local PerfectChestDialog = class2("PerfectChestDialog",function()
    return BaseView.new("PerfectChestDialog.json")
end)

function PerfectChestDialog:ctor(params,callback)
    self.callback = callback
    self.p = params
    self.params = params[4]
    self.itemIdx = params[3]
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function PerfectChestDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self:loadView("views")
    self:loadView("receiveButton")
    self:initRewardViews()
	viewTab.butReceive:setListener(function()
        self:getpvjgift()
    end)


    local sign
    local idx = self.itemIdx
    if self.params.gift[idx] and self.params.gift[idx][3]==1 then
        sign = true
    else
        sign = false
    end

    local up = (idx-1)*8+1
    local stars = 0
    for i=up,up+7 do
        if self.params.quests[i] then
            stars = stars+self.params.quests[i][2]
        end
    end
    local sign2 = true
    if stars==24 then
        sign2 = false
    end
    self.p[1],self.p[2] = sign,sign2


    if self.p[1] then
        viewTab.butReceive:removeFromParent(true)
        self:loadView("alreadyReceiveView")
    end
    if self.p[2] then
        viewTab.butReceive:setEnable(false)
        viewTab.butReceive:setGray(true)
    end
    self:insertViewTo()
    if not sign then
        if self.labelAlreadyReceive then
            self.labelAlreadyReceive:setVisible(false)
        end
    end
end

function PerfectChestDialog:showAlreadyReceive()
    self.butReceive:removeFromParent(true)
    self:loadView("alreadyReceiveView")
end

function PerfectChestDialog:initRewardViews()
	local pos={{98,732},{672,732},{98,488},{672,488},{98,244},{672,244}}
	local bg,temp

    local giftContent = SD("pvjgift",self.p[3])

    local i = 0
	for k,v in pairs(giftContent) do
        i = i+1
		bg = ui.node()
        display.adapt(bg,pos[i][1],pos[i][2], GConst.Anchor.LeftBottom)
        self:addChild(bg)
        --添加物品
        --GameUI.addItemIcon(bg, 2, 1,0,0)

        GameUI.addItemIcon(bg,v.itemtype,v.itemid,1,91,90,true)
        --物品名称
        local name = GameLogic.getItemName(v.itemtype,v.itemid)
        
        temp = ui.label(StringManager.getString(name), General.font1, 45, {color={255,255,255},fontW=260,fontH=80})
		display.adapt(temp, 222, 183, GConst.Anchor.LeftTop)
		bg:addChild(temp)
		temp = ui.label(StringManager.getString("x"..v.itemnum), General.font1, 45, {color={255,255,255}})
		display.adapt(temp, 222, 115, GConst.Anchor.LeftTop)
		bg:addChild(temp)
	end
end
------------------------------------------------------------------------------------
function PerfectChestDialog:getpvjgift()
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdPvjGift,self.itemIdx})
    print("领取成功！！")
    self.params.gift[self.itemIdx] = {self.itemIdx,1,1}

    --changRes
    local giftContent = SD("pvjgift",self.itemIdx)
    local i = 0
    local reward = {}
    for k,v in pairs(giftContent) do
        i = i+1
        reward[i] = {v.itemtype,v.itemid,v.itemnum}
    end
    GameLogic.addRewards(reward)
    GameLogic.statCrystalRewards("pvj完美通关宝箱奖励",reward)
    display.pushNotice(Localize("stringGetSucceed"))
    if self.showAlreadyReceive then
        self:showAlreadyReceive()
    end
    self.callback()
end



return PerfectChestDialog




