
local WarReportIn = class2("WarReportIn",function()
    return BaseView.new("WarReportIn.json",true)
end)

function WarReportIn:ctor(data,callback)
    self.params = data
    self.callback = callback
    self:initUI()
    display.showDialog(self,false)
    self.atkEndTime = self.params.atktime + GameLogic.getSTime()
    RegActionUpdate(self, Handler(self.updateMy, self, 0.2), 0.2)
end
function WarReportIn:initUI()
    self:loadView("mainView")
    self:insertViewTo()
end

function WarReportIn:updateMy(diff)
    local rm = self.atkEndTime - GameLogic.getSTime()
    if rm>0 then
        self.lbRemainTime:setString(Localizet(rm))
    else
        if self.callback then
            self.callback()
            display.closeDialog(0)
            self.callback = nil
        end
    end
end

return WarReportIn
