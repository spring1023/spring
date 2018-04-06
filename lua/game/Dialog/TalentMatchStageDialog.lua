local TalentMatchStageDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")

function TalentMatchStageDialog:onInitDialog()
    self:setLayout("TalentMatchStageDialog.json")
end

function TalentMatchStageDialog:onEnter()
    self:initUI()
    self:initData()
end

function TalentMatchStageDialog:initUI()
    local stage = self.ainfo.adata.stage
    self.title:setString(Localize("dataTMStageType" .. stage))
    self.imgRankTitle:setImage("images/matchs/bannerMatch" .. self.ainfo.aid .. ".png", 0)
    self.labelRankInfo:setString(Localize("dataTMStageDesc"))
    self.imgRankTitle.view:setFlippedX(true)
    self.questionBut:setVisible(false)
    GameUI.setTMStageIcon(self.myStageIcon, stage, self.context.talentMatch:getStage(stage))
end

-- 数据
function TalentMatchStageDialog:initData()
    local stage = self.ainfo.adata.stage
    local stages = {}
    for lv, sdata in ipairs(SData.getData("tmStages", stage)) do
        table.insert(stages, {idx=lv, data=sdata, stage=stage})
    end
    self.stageTableView:setLazyTableData(stages, Handler(self.onUpdateStageCell, self), 0)
end

-- 数据
function TalentMatchStageDialog:onUpdateStageCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    local height = 400 + (info.idx-1) * 40
    reuseCell.imgColor:setSize(reuseCell.imgColor.size[1], height)
    reuseCell.iconStage:setPositionY(height)
    reuseCell.labelStageName:setPositionY(height-200)
    GameUI.setTMStageIcon(reuseCell.iconStage, info.stage, info.idx)
    reuseCell.labelStageName:setString(Localize("descTmIcon" .. info.stage .. "_" .. info.idx))
    return reuseCell
end

return TalentMatchStageDialog
