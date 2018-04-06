local TalentMatchUpgradeDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")

function TalentMatchUpgradeDialog:onInitDialog()
    self:setLayout("TalentMatchUpgradeDialog.json")
end

function TalentMatchUpgradeDialog:onEnter()
    memory.loadSpriteSheetRelease("images/rankNums.plist", false)
    local stage = self.ainfo.adata.stage
    self.imgRankTitle:setImage("images/matchs/bannerMatch" .. self.ainfo.aid .. ".png", 0)
    self.imgRankTitle.view:setFlippedX(true)
    self.questionBut:setVisible(false)
    GameUI.setTMStageIcon(self.myStageIcon, stage, self.context.talentMatch:getStage(stage))
    self.btnInfo:setScriptCallback(ButtonHandler(display.sendIntent, {
        class="game.Dialog.TalentMatchStageDialog", params={ainfo=self.ainfo}
    }))

    local tab = DialogTemplates.createTabView(self.nodeTabs, {Localize("titleStageRank"), Localize("titleStageRank2")},
        Handler(self.onChangeTab, self), {543,149,468,0,87,"images/dialogTabBack3_",
        55,271,69,1540,57,43,-46})
    tab:changeTab(1)
end

function TalentMatchUpgradeDialog:onExit()
    memory.releasePlist("images/rankNums.plist", false)
end

function TalentMatchUpgradeDialog:onChangeTab(idx)
    self.__selectedIdx = idx
    local stage = self.ainfo.adata.stage
    self.rankTableView:setVisible(false)
    self.rankEmpty:setVisible(false)
    local curStage = self.context.talentMatch:getStage(stage)
    self.context.talentMatch:getRankDataForStage(stage, idx == 1
        and curStage or 0, Handler(self.onRefreshRankData, self, idx))
end

function TalentMatchUpgradeDialog:onRefreshRankData(idx, rankDatas)
    if self.deleted or idx ~= self.__selectedIdx then
        return
    end
    local stage = self.ainfo.adata.stage
    if idx == 1 then
        local curStage = self.context.talentMatch:getStage(stage)
        if curStage == 9 then
            self.labelRankInfo:setString(Localize("labelStageDesc3"))
        else
            local openMax = rankDatas.openMax or {0, 2}
            if openMax[2] <= curStage then
                self.labelRankInfo:setString(Localizef("labelStageDesc1", {n=curStage}))
            else
                self.labelRankInfo:setString(Localizef("labelStageDesc", {n=curStage}))
            end
        end
    else
        self.labelRankInfo:setString(Localize("labelStageDesc2"))
    end
    if #(rankDatas.rankData) > 0 then
        self.bgColor:setColor(121,113,99)
        self.rankTableView:setVisible(true)
        self.rankEmpty:setVisible(false)
        self.rankTableView:setLazyTableData(rankDatas.rankData, Handler(self.onUpdateRankCell, self), 0)
        -- if idx == 1 then
        --     for idx2, data in ipairs(rankDatas.rankData) do
        --         if data.id == self.context.uid then
        --             self.rankTableView:locationIndex(idx2)
        --         end
        --     end
        -- end
    else
        self.rankTableView:setVisible(false)
        self.rankEmpty:setVisible(true)
        self.bgColor:setColor(235, 217, 182)
    end
    GameUI.registerVisitBack(self, self.rankTableView)
end

function TalentMatchUpgradeDialog:onUpdateRankCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end

    -- 通用排行数字
    GameUI.setRankNumber(reuseCell.playerRank, info.rank)
    -- 通用框逻辑，TODO 封装一下
    GameUI.setAngleView(reuseCell.imgSpecialLeft, 1, 75)
    GameUI.setAngleView(reuseCell.imgSpecialRight, 4, 75)
    reuseCell.imgSpecialLeft:setVisible(info.rank <= 3)
    if info.id == self.context.uid then
        ui.setColor(reuseCell.imgBackColor, 207, 255, 186)
        ui.setColor(reuseCell.imgSpecialLeft, 174, 227, 151)
        ui.setColor(reuseCell.imgSpecialRight, 174, 227, 151)
    elseif info.rank == 1 then --第一名
        ui.setColor(reuseCell.imgBackColor, 235, 211, 146)
        ui.setColor(reuseCell.imgSpecialLeft, 230, 189, 63)
        ui.setColor(reuseCell.imgSpecialRight, 230, 189, 63)
    elseif info.rank == 2 then --第二名
        ui.setColor(reuseCell.imgBackColor, 196, 209, 218)
        ui.setColor(reuseCell.imgSpecialLeft, 149, 194, 215)
        ui.setColor(reuseCell.imgSpecialRight, 149, 194, 215)
    elseif info.rank == 3 then--第三名
        ui.setColor(reuseCell.imgBackColor, 215, 180, 146)
        ui.setColor(reuseCell.imgSpecialLeft, 203, 149, 86)
        ui.setColor(reuseCell.imgSpecialRight, 203, 149, 86)
    else
        ui.setColor(reuseCell.imgBackColor, 255, 241, 211)
        ui.setColor(reuseCell.imgSpecialRight, 229, 214, 182)
    end

    local headInfo = reuseCell._headInfo
    if not headInfo then
        headInfo = {headScale=1, isLeft=true, notBlack=true, back=ui.node()}
        display.adapt(headInfo.back, reuseCell.playerHead.size[1]/2, reuseCell.playerHead.size[2]/2)
        reuseCell.playerHead:addChild(headInfo.back)
        headInfo.back:setScale(reuseCell.playerHead.size[1] / 150)
        reuseCell._headInfo = headInfo
    end
    headInfo.iconType = info.head
    headInfo.level = info.level
    GameUI.updateUserHeadTemplate(headInfo.back, headInfo)

    reuseCell.playerName:setString(info.name)

    GameUI.setTMStageIcon(reuseCell.stageIcon, self.ainfo.adata.stage, info.stage)
    reuseCell.rankLabel:setString(tostring(info.score))
    reuseCell.dotteLine:setVisible(info.isNewLine and true or false)
    GameUI.registerVisitButton(reuseCell.btnVisitUser, self, tableView, reuseCell.playerName, info)
    return reuseCell
end

return TalentMatchUpgradeDialog
