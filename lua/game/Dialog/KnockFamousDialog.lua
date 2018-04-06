local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockFamousDialog = class(DialogViewLayout)
function KnockFamousDialog:onInitDialog()
	self.canClickBtn = false
    self:initUI()
    self:initData()
end

function KnockFamousDialog:initUI()
	self:setLayout("KnockFamousDialog.json") 
    self:loadViewsTo()
    self.questionBut:setScriptCallback(ButtonHandler(self.onQuestion,self))
end

function KnockFamousDialog:initData()
	self.man = {}
	local function callback(isSuc, data)
        GameUI.setLoadingShow("loading", false, 0)
		if isSuc then 
            if self.deleted then 
                return
            end
			self:updateData(data)
		end
	end
    GameUI.setLoadingShow("loading", true, 0)
    GameNetwork.request("getHistroyCp", nil, callback)
end

function KnockFamousDialog:updateData(data)
    self.canClickBtn = true
	self.man = data.his
	self:updateUI()
end

function KnockFamousDialog:updateUI()
    local man = clone(self.man)
    table.sort( man, function(a, b) 
        local info1 = json.decode(a[2])
        local info2 = json.decode(b[2])
        return info1[5] < info2[5]
    end)
	if not GameLogic.isEmptyTable(man) then
		local tab = GameUI.helpLoadTableView(self.nd_playerModelBottom,man,Handler(self.updateManItem,self))
        local len = #man
        if len <= 4 then 
            tab.view:setElastic(false)
            local xPos, y = self:getPosByNum(len)
            for k, v in ipairs(tab.Cell) do
                v:setPosition(xPos[k], y)
            end
        elseif len > 4 then 
            tab.view:setElastic(true)
        end
	end
end

function KnockFamousDialog:getPosByNum(num)
    local pos= {}
    pos[1] = {954}
    pos[2] = {724, 1184}
    pos[3] = {494, 954, 1414}
    pos[4] = {264, 724, 1184, 1644}
    return pos[num], 425
end

function KnockFamousDialog:updateManItem(cell,tableView,info)
	if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("nd_playerModel",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        local _info = json.decode(info[2])
        local name = _info[1]
        local lv = _info[2]
        local head = _info[3]
        local combat = _info[4]
        local season = _info[5]-1  
        info.lb_week:setString(Localizef("labSeasonChampion", {num = season}))
        info.lb_name:setString(name)
        info.lb_lv:setString(lv)
        info.lb_combat:setString(Localizef("labPvzCombat", {num = combat}))
        GameUI.addPlayHead(info.nd_headModelBottom, {id=head, scale = 1.5, x=0,y=0,z=0,blackBack=true, noBlackBack = false})
    	info.btn_getGrade:setScriptCallback(self.jumpToOutSecondDialog, self, _info)
    end
end

function KnockFamousDialog:jumpToOutSecondDialog(info)
    if not self.canClickBtn then 
        return 
    end
    local season = info[5]
    local KnockOutSecondDialog = GMethod.loadScript("game.Dialog.KnockOutSecondDialog")
    display.showDialog(KnockOutSecondDialog.new({wk = 0, season = season}))
end

function KnockFamousDialog:onQuestion()
    HelpDialog.new("pvzFamousManInfoQuestion")
end

function KnockFamousDialog:closeDialog()
    display.closeDialog()
    local KnockMainDialog = GMethod.loadScript("game.Dialog.KnockMainDialog")
    display.showDialog(KnockMainDialog.new())
end

return KnockFamousDialog