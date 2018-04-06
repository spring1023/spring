local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local SData = GMethod.loadScript("data.StaticData")
local KnockDivideStageDialog = class(DialogViewLayout)
function KnockDivideStageDialog:onInitDialog()
   self:initUI()
   self:initData()
end

function KnockDivideStageDialog:initData()

end

function KnockDivideStageDialog:initUI()
	self:setLayout("KnockDivideStageDialog.json")
    self:loadViewsTo()
    self:updateUI()
end

function KnockDivideStageDialog:updateUI()
	self.questionBut:setVisible(false)
    local stageInfos = KnockMatchData:getAlldReward()
	GameUI.helpLoadTableView(self.nd_stage,stageInfos,Handler(self.updateStageItem,self))
end

function KnockDivideStageDialog:updateStageItem(cell, tableView, info)
	if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("nd_itemStage",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        local statue = {}
        local maxGrade = self:getMaxGrade()
        local str = ""
        if info.max == maxGrade then
            str = str..info.min.." "..Localize("labAbove")
        else
            str = str..info.min.." "..Localize("labTo").." "..info.max
        end
        local stage = info.stage
        -- dump(info)
        KnockMatchData:changeStageIcon(info.img_atk, stage)
        -- local path = KnockMatchData:getStageIconPath(stage)
        -- info.img_atk.view:setTexture(path)
        info.lb_getScore:setString(str)
        --添加神像
        if not GameLogic.useTalentMatch then
            local newBuild = Build.new(187, stage)
            local vs = 5
            local stage = info.stage
            local hpAct = SData.getData("bdatas")[50107][stage].hpRate.."%"
            newBuild:addBuildView(info.btn_statueReward.view:getDrawNode(), 74, 53, 80, 80, vs)
            info.btn_statueReward.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self.view, info.btn_statueReward.view, info.btn_statueReward.size[1]/2, info.btn_statueReward.size[2]/2, Localizef("labStatueTip", {a = hpAct})}))
        else
            GameUI.addItemIcon(info.btn_statueReward, info.week[1][1], info.week[1][2], 148/200, 74, 74, true, false, {itemNum=info.week[1][3]})
            GameUI.registerTipsAction(info.btn_statueReward, self.view, info.week[1][1], info.week[1][2])
        end
        info.btn_statueReward.view:setTouchThrowProperty(true, true)
        local data = SData.getData("bdatas")
        local function _updateRewardItem(_cell, _tableView, _info)
            if not _info.viewLayout then
                _info.cell = _cell
                _info.viewLayout = self:addLayout("nd_itemReward", _cell:getDrawNode())
                _info.viewLayout:loadViewsTo(_info)
                local type = checknumber(_info[1])
                local id = checknumber(_info[2])
                local num = checknumber(_info[3])
                GameUI.addItemIcon(_info.nd_itemRewardBottom.view, type, id, 148/200, 74, 74,true,false,{itemNum=num})
            end
        end
        local rwds = clone(KnockMatchData:getdRewardByScore(info.min+1))
        local len = #rwds
        local tab = GameUI.helpLoadTableView(info.nd_reward, rwds, Handler(_updateRewardItem))
        tab.view:setTouchThrowProperty(true, true)
        if len <= 4 then
            tab.view:setElastic(false)
        end
    end
end

function KnockDivideStageDialog:getMaxGrade()
    local stageInfos = KnockMatchData:getAlldReward()
    local grade = 0
    for k, v in pairs(stageInfos) do
        if v.max > grade then
            grade= v.max
        end
    end
    return grade
end

return KnockDivideStageDialog
