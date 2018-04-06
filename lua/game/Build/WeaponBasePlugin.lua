local WeaponBasePlugin = {}

function WeaponBasePlugin:addMenuButs(buts, item)
    if item=="expedition" then
        --table.insert(buts, {key="expedition", callback=self.showPvhDialog, cp1=self})
        table.insert(buts, {key="expedition", callback=function()
            self:showPvhDialog()
            local context = GameLogic.getUserContext()
            local step = context.guideOr:getStep()
            if step == 35 then
                context.guideOr:setStep(step+1)
                context.guideHand:removeHand("guideOrBuildBtn")
            end
        end})
    elseif not self.worklist then
        if item=="research" then
            table.insert(buts, {key="research", callback=display.showDialog, cp1=WeaponUpgradeDialog})
        else
            table.insert(buts, {key="create", callback=display.showDialog, cp1=WeaponProduceDialog})
        end
    end
end

function WeaponBasePlugin:showPvhDialog()
    if self.rlock then
        return
    end
    local context = GameLogic.getUserContext()
    if not context.pvh then
        self.rlock = true
        GameNetwork.request("pvhinfo",nil,self.onResponsePvhInfo, self)
        return
    end
    if context.pvh:isInBattle() then
        display.showDialog(PvhMapDialog)
    else
        display.showDialog(PvhDialog)
    end
end

function WeaponBasePlugin:onResponsePvhInfo(suc, data)
    self.rlock = nil
    if suc then
        local context = GameLogic.getUserContext()
        context:loadPvh(data)
        if self.vstate and self.vstate.scene.sceneType=="operation" then
            self:showPvhDialog()
        end
    end
end

function WeaponBasePlugin:updateOperation(diff)
    local context = self.context
    local wdata = context.weaponData
    local lt, mt = nil, nil
    local stime = GameLogic.getSFloatTime()
    mt = wdata:getNextUseTime()
    if mt then
        lt = mt+wdata:getProduceStartTime()-stime
    end
    self:setWorkProcess(lt, mt)
end

return WeaponBasePlugin
