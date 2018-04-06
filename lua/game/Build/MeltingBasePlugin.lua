local MeltingBasePlugin = {}

function MeltingBasePlugin:addMenuButs(buts, item)
    if self.worklist then
        return
    end
    if not self.wlist then
        if item=="melting" then
            table.insert(buts, {key="melting", callback=function()
                MeltingAddHeroDialog.new()
                local context = GameLogic.getUserContext()
                local step = context.guideOr:getStep()
                if step == 65 then
                    context.guideOr:setStep(step+1)
                    context.guideHand:removeHand("guideOrBuildBtn")
                end
            end})
        elseif item=="singed" then
            table.insert(buts, {key="singed", callback=MeltingDialog.new})
        end
    end
end


function MeltingBasePlugin:updateOperation(diff)
	local vstate = self.vstate
	local blv = self.level
	local views=vstate.bviews
    local onAlchemy = GameLogic.getUserContext().meltData.onAlchemy
	if blv<8 then
        if onAlchemy[3] and onAlchemy[3]-GameLogic.getSTime()>0 then
		    views[1]:setVisible(true)
        else
            views[1]:setVisible(false)
        end
	elseif blv<=10 then
        if onAlchemy[3] and onAlchemy[3]-GameLogic.getSTime()>0 then
            views[1]:setVisible(true)
            views[2]:setVisible(true)
            views[3]:setVisible(true)
            views[4]:setVisible(true)
        else
            views[1]:setVisible(false)
            views[2]:setVisible(false)
            views[3]:setVisible(false)
            views[4]:setVisible(false)
        end
	end
    if not vstate.buildName then
        if onAlchemy[3] and onAlchemy[3]-GameLogic.getSTime()<=0 then
            self:reloadUpText(1, Localize("labelGaFinish"))
        else
            self:reloadUpText(0, Localize("labelGaFinish"))
        end
    end
end

return MeltingBasePlugin
