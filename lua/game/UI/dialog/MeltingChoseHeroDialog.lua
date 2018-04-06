local SData = GMethod.loadScript("data.StaticData")--选择熔炼英雄对话框
local MeltingChoseHeroDialog = class2("MeltingChoseHeroDialog",function()
    return BaseView.new("MeltingChoseHeroDialog.json",true)
end)

function MeltingChoseHeroDialog:ctor(heros,callback)
    self.callback = callback
    self.herosMap = {}
    for i,v in ipairs(heros) do
        self.herosMap[v] = true
    end
    self.bheroNum = #heros

    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function MeltingChoseHeroDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))

    self:loadView("allViews")
    self:loadView("leftBack")

    local context = GameLogic.getUserContext()
    local allHeros = context.heroData:getAllHeros()
    local heros = {}
    for k,v in pairs(allHeros) do
        local hero=SData.getData("hinfos",v.hid)
        if hero.rating>=3 and v.hid%1000~=0 and v.lock==0 and not self.herosMap[v] == true then
            table.insert(heros,v)
        end
    end
    --根据等级排序
    table.sort(heros,function(a,b) return a.level>b.level end)
    local infos={}
    for i=1,#heros do
        infos[i]={id=i,hero = heros[i]}
    end
    self:addTableViewProperty("heroTableViews",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("heroTableViews")
    self:insertViewTo()
    self.selectHero = {}
    self.selectHeroNum = 0
    self.butSure:setListener(function()
        local selectHero = {}
        for k,v in pairs(self.selectHero) do
            if v.forceState then
                table.insert(selectHero,v.hero)
            end
        end
        if self.bheroNum+#selectHero>20 then
            display.pushNotice(Localize("labelSemltMore"))
        else
            self.callback(selectHero)
            display.closeDialog(0)
        end
    end)
    if #infos==0 then
        self:loadView("notInfoViews")
        self:insertViewTo()
        self.talkInfo:setString(StringManager.getString("labelTalkInfo4"))
    end
end
function MeltingChoseHeroDialog:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    GameUI.updateHeroTemplate(bg, info, info.hero, {flagState = true,flagEquip = true})
    ui.setListener(cell,function()
        local callback = function()
            info.forceState = not info.forceState
            if info.forceState then
                if self.bheroNum+self.selectHeroNum+1>20 then
                    info.forceState=false
                    display.pushNotice(Localize("labelSemltMore"))
                else
                    self.selectHeroNum =self.selectHeroNum+1
                    table.insert(self.selectHero,info.id,info)
                end
            else
                self.selectHeroNum = self.selectHeroNum-1
                table.remove(self.selectHero,info.id)
            end
            GameUI.updateHeroTemplate(bg, info, info.hero, {flagState = true,flagEquip = true})
        end
        if not GameLogic.checkHero(info.hero) then
            display.showDialog(AlertDialog.new(3,Localize("alertTitleNormal"),Localize("alertTextHeroState"),{callback=Handler(self.onForceSelect, self, info, bg)}))
        elseif info.hero.equip and not info.forceState then
            local otherSettings = {callback = function()
                GameLogic.getUserContext().equipData:changeEquipHero(info.hero.equip, nil)
                callback()
            end}
            local dl = AlertDialog.new(3,Localize("alertTitleNormal"),Localize("labelIsCancelEquip"),otherSettings)
            display.showDialog(dl)
        elseif not GameLogic.checkHeroDv(info.hero) and not info.forceState then
            local otherSettings = {callback = callback}
            local dl = AlertDialog.new(3,Localize("alertTitleNormal"),Localize("labelIsHeroDevelop"),otherSettings)
            display.showDialog(dl)
        else
            callback()
        end
    end)
end
function MeltingChoseHeroDialog:onForceSelect(info, bg)
    local heroData = GameLogic.getUserContext().heroData
    local hero = heroData:getHero(info.hero.idx)
    local layouts = hero.layouts
    for lid, _ in pairs(layouts) do
        heroData:changeHeroLayout(hero, lid, 0, 0)
    end
    GameUI.updateHeroTemplate(bg, info, info.hero, {flagState = true,flagEquip = true})
end
return MeltingChoseHeroDialog









