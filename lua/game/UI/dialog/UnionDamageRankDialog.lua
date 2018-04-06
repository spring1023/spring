
local SData = GMethod.loadScript("data.StaticData")
--联盟伤害排名对话框
local UnionDamageRankDialog = class2("UnionDamageRankDialog",function()
    return BaseView.new("UnionDamageRankDialog.json",true)
end)

function UnionDamageRankDialog:ctor(index)
    self.index = index
    self:initBack()
    self:getpvldamagelist()
    display.showDialog(self)
end
function UnionDamageRankDialog:onQuestion()
    HelpDialog.new("dataQuestionUnDgRk")
end
function UnionDamageRankDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,display.getDialogPri()+1))
end

function UnionDamageRankDialog:initUI()
    self:loadView("leftViews")
    self:loadView("rightViews")

    --左边头像
    local bsdata = SData.getData("upveboss",self.index,1)
    local id = bsdata[1]
    local lv = bsdata[2]
    if id<100 then
        GameUI.addBuildHead(self,id,467,402,189+233,386+201,2, lv)
    else
        --GameUI.addHeroHead(self,id,{size={467,402},x=189+233,y=360+201,z=2})    --boss头像
        local context = GameLogic.getUserContext()
        local hero = context.heroData:makeHero(id)
        local headNode = ui.node({200,200})
        display.adapt(headNode,189+195,386+201,GConst.Anchor.Center)
        self:addChild(headNode)
        headNode:setScale(1.5)
        GameUI.updateHeroTemplate(headNode, {noLv = true}, hero)
    end
    self:insertViewTo()
    self.labelOutpost:setString(Localize("dataPvlPassName" .. self.index))
    local infos={}
    for i=1,#self.params do
        infos[i]={id=i}
    end
    self:addTableViewProperty("rankTableView",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("rankTableView")
end

function UnionDamageRankDialog:callcell(cell, tableView, info)
    local item = self.params[info.id]

    local bg = cell:getDrawNode()
    cell:setEnable(false)
    if info.id%2==1 then
       self:loadView("cellBack1",bg)
    else
       self:loadView("cellBack2",bg)
    end
    if info.id==1 then
    	self:loadView("lastAttackView",bg)
    end
    self:loadView("cellViews",bg)
    self:insertViewTo()
    --名次
    self.labelRankNumberBoxValue:setString(info.id)
    --名字
    self.labelCellName:setString(item.name)
    --伤害
    local damageStr = item.damage
    if item.damage>1000 then
        damageStr = string.format("%.2f", item.damage/1000) .. "K"
    elseif item.damage>1000000 then
        damageStr = string.format("%.2f", item.damage/1000000) .."M"
    end
    self.labelMoneyValue:setString(damageStr)
    --宝箱数
    local idx = 0
    local boxCf = SData.getData("upvebox",self.index)
    if info.id == 1 then
        idx = 1
    elseif 1<info.id and info.id<6 then
        idx = 2
    elseif 5<info.id and info.id<11 then
        idx = 3
    end

    local bn = boxCf[idx] or 0
    local all = bn+boxCf[4]+boxCf[5]
    self.labelCellCanGetValue:setString("x" .. all)
end


function UnionDamageRankDialog:getpvldamagelist()
    _G["GameNetwork"].request("getpvldamagelist",{getpvldamagelist={self.index}},function(isSuc,data)
        if isSuc then
            print_r(data)
            local params = {}
            for i,v in pairs(data) do
                params[i] = {
                    name = v[4] or "",
                    damage = v[2],
                }
            end

            for i=1,#params do
                for j=1,#params-i do
                    if params[j].damage<params[j+1].damage then
                        params[j],params[j+1] = params[j+1],params[j]
                    end 
                end
            end

            self.params = params
            if self.initUI then
                self:initUI()
            end
        end
    end)
end


return UnionDamageRankDialog
