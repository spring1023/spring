
local SeeArenaArrDialog = class2("SeeArenaArrDialog",function()
    return BaseView.new("SeeArenaArrDialog.json")
end)

function SeeArenaArrDialog:ctor(idx,enemy,callback)
    self.callback = callback
    self.dialogDepth=display.getDialogPri()+1
    self:initUI(idx,enemy)
    self:pvcdata(enemy)
    self.priority=self.dialogDepth
    display.showDialog(self)
end

function SeeArenaArrDialog:initUI(idx,enemy)
    self:loadView("viewMain")
    self:insertViewTo()
    self.butClose:setListener(function()
        display.closeDialog(0)
    end)
    self.lbTitle:setString(Localizef("stringSeeArr",{name=enemy.name}))
    local arena= GameLogic.getUserContext().arena

    if enemy.isRevenge then
        self.butChallenge:setHValue(-78)
        self.btnChallenge:setString(Localize("btnRevenge"))
    else
        self.butChallenge:setHValue(0)
        self.btnChallenge:setString(Localize("btnChallenge"))
    end
    if arena:getCurrentChance()<=0 then
        self.butChallenge:setGray(true)
    else
        self.butChallenge:setGray(false)
    end
    
end

function SeeArenaArrDialog:initContent(econtext)
    local heros = {}
    for i=1,5 do
        local hero = econtext.heroData:getHeroByLayout(const.LayoutPvc,i,1)
        if hero then
            table.insert(heros,hero)
        end
    end
    for i,hero in ipairs(heros) do
        local bg = ui.node()
        bg:setScale(0.8)
        display.adapt(bg, 80+230*(i-1), 400, GConst.Anchor.Center)
        self:addChild(bg)
        GameUI.updateHeroTemplate(bg, {}, hero, {})
    end
    self.butChallenge:setListener(function()
        self.callback()
    end)
end

-------------------------------------------------
function SeeArenaArrDialog:pvcdata(enemy)
    local uid = enemy.uid
    local rank = enemy.rank
    if dataCache:get("pvcdata" .. uid) then
        self:getArenaDataOver(dataCache:get("pvcdata" .. uid),uid)
    else
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("pvcheros", {tid=uid}, function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                if self.getArenaDataOver then
                    self:getArenaDataOver(data,uid)
                end
            end
        end)
    end
end

function SeeArenaArrDialog:getArenaDataOver(data,uid)
    local econtext = GameLogic.newContext(uid)
    local edata = {builds={}, layouts={}, bexts={}, wlist={}, armors={}}
    edata.info = {}
    edata.heros = {}
    edata.hlayouts = {}
    edata.hbskills = {}
    edata.equips = GameLogic.transEquipData(data.equips)
    local bidx = 0
    for i,v in ipairs(data.heros) do
        local hero = {v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8],v[9],v[10],v[11],v[12],0,0}
        local hlayout = {v[1],const.LayoutPvc,v[13]}
        table.insert(edata.heros,hero)
        table.insert(edata.hlayouts,hlayout)
        if math.floor(v[13]/10000)%10==1 then
            bidx = math.floor(v[13]/100000)
            if bidx<=5 then
                local xy = v[13]%10000
                table.insert(edata.builds,{bidx, const.HeroBase, 1})
                table.insert(edata.layouts,{bidx, 36-math.floor(xy/100),36-xy%100,0,0,0,0})
            end
        end
    end
    local mbidx = 100
    table.insert(edata.builds, {mbidx, const.Town, data.uinfo[3]})
    table.insert(edata.layouts, {mbidx, 19, 37, 0, 0, 0, 0})
    table.insert(edata.bexts,{mbidx, 0, 0})
    econtext:loadContext(edata)
    if self.initContent then
        self:initContent(econtext)
    end
end

return SeeArenaArrDialog
