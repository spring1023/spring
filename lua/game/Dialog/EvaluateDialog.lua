-- Depiction：评分引导
-- Author：XiaoGangMu
-- Create Date：2019-2-10
EvaluateDialog = class(DialogViewLayout)

function EvaluateDialog:onInitDialog()
    self:setLayout("EvaluateDialog.json")
    self:loadViewsTo()
    local function closeDialog()
       display.closeDialog(0)
    end
    self.dialogDepth=display.getDialogPri()+1
    self.closeBut:setScriptCallback(closeDialog)
    display.showDialog(self)
end

function EvaluateDialog:onExit()
    if self.callback then
        self.callback()
    end
end

function EvaluateDialog:onEnter()
    self.evaluateName:setString(Localize("evaluateName"))
    self.closeBtn:setString(Localize("closeBtn"))
    self.goEvaluate:setString(Localize("goEvaluate"))
    local language = General.language
    if (language == "CN" or language == "HK") and cc.FileUtils:getInstance():isFileExist("images/evaluatecon1.png") then
        ui.setFrame(self.evaluatecon.view,"images/evaluatecon1.png")
    else
        ui.setFrame(self.evaluatecon.view,"images/evaluatecon2.png")
    end
    self.btnclose:setScriptCallback(function()
        Plugins:onStat({callKey=5,eventId="evaluate",params={taskType="closeBtn",cause="残忍拒绝"}})
        display.closeDialog(self.dialogDepth)
    end)

    self.btngoeva:setScriptCallback(function()
        Plugins:onStat({callKey=5,eventId="evaluate",params={taskType="evaluate",cause="去评价"}})
        GameLogic.doRateAction()
    end)
end
