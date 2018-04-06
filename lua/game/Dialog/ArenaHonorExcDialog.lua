local SData = GMethod.loadScript("data.StaticData")
--竞技场兑换
ArenaHonorExcDialog = class(DialogViewLayout)

function ArenaHonorExcDialog:onInitDialog()
    self:setLayout("ArenaHonorExcDialog.json")
    self:loadViewsTo()
    self.stage = self.params.stage
    self.title:setString(Localizef("labArenaStage",{n=self.stage}))
    self.labExcPrice:setString(self.params.price)
    local infos = GameLogic.getUserContext().arena:getHonorInfos()
    local notEnough =false
      if infos.honorHave<self.params.price then
          notEnough = true
          self.btnExc:setGray(true)
      end
    self.btnExc:setScriptCallback(ButtonHandler(function ()
        if notEnough then
            display.pushNotice(Localize("noticeHonorNotEnough"))
        else
            self:onExc()
        end
    end))
end

function ArenaHonorExcDialog:onEnter()
    GameUI.addArenaBoxIcon(self.view, self.stage, 1, 231, 518, 0)
    --5月2号2点
    local endTime = 1493704800
    if GameLogic.getSTime() < endTime then
        local t=endTime - GameLogic.getSTime()
        self.labGetPrestigeTips:setString(Localizef("labGetPrestigeTips",{time=Localizet(t)}))
    end
    --声望再见！
    if GameLogic.useTalentMatch then
        self.labGetPrestige:setVisible(false) 
    else
        self.labGetPrestige:setString(Localizef("labGetPrestige",{a=self.params.canGetHonor}))
    end  
    local rwds = self.params.rwds
    local infos={}

    for i,v in ipairs(rwds) do
        if v[1]==const.ItemPopValue then
            if v[2]>5000 then
                local info=self:getFragment(v)
                table.insert(infos,info)
            else
                table.insert(infos,{const.ItemFragment,0,v[3]})
            end
        elseif v[1]==13 then
            table.insert(infos,{const.ItemFragment,0,v[4] or v[3]})
        else
            table.insert(infos,v)
        end
    end
    self.nodeTableView:loadTableView(infos, Handler(self.onUpdateCell, self))
end

function ArenaHonorExcDialog:getFragment(v)
    local poplevel = GameLogic.getUserContext():getProperty(const.ProPopLevel)
    poplevel = poplevel + const.FreePopIdx + 1 - (v[2] % 1000)
    if poplevel < 1 then
        poplevel = 1
    end
    local info = {}
    local popItem = SData.getData("popunlock", poplevel)
    if popItem.unLockType == const.ItemEquip then
        info[1] = const.ItemEquipFrag
    else
        info[1] = const.ItemFragment
    end
    info[2] = popItem.unLockId
    info[3] = v[3]
    return info
end
function ArenaHonorExcDialog:onUpdateCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    local item=info
    GameUI.addItemIcon(bg,item[1],item[2],0.8,93,93,true,false,{itemNum=item[3]})
end

function ArenaHonorExcDialog:onExc()
    if self.deleted then
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("pvcbuybox",{grade=self.stage}, function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code and data.code==1 then
                print("资源不足")
            else
                local context = GameLogic.getUserContext()
                local vip = context:getInfoItem(const.InfoVIPlv)
                local stage = context.arena:getCurrentStage()
                local price = self.params.price
                GameLogic.addStatLog(11502,vip,stage,price)

                display.closeDialog(self.priority)
                GameLogic.getUserContext():changeProperty(const.ProPopular,data.popular)
                local arena = GameLogic.getUserContext().arena
                GameLogic.addRewards(data.agl)
                GameLogic.showGet(data.agl,0.5,true,true)
                arena:refreshHonor(data.avalue,data.atime)
                GameEvent.sendEvent("refreshHonorShop")
                GameEvent.sendEvent("refreshArenaDialog")
            end
        end
    end)

end