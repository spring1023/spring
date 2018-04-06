local BuildProcess = class()

function BuildProcess:ctor(ptype, max)
    self.view = ui.node({183, 29}, true)
    local bg = ui.sprite("images/proBackHp.png", {183, 29})
    display.adapt(bg, 0, 0)
    self.view:addChild(bg)
    self.max = max
    self.value = -1
    self.ptype = ptype
    self:resetTexture()
    local label = ui.label("", General.font1, 30)
    display.adapt(label, 91, 30, GConst.Anchor.Bottom)
    self.view:addChild(label)
    self.timeLabel = label
end

function BuildProcess:setType(ptype)
    if ptype~=self.ptype then
        self.ptype = ptype
        self:resetTexture()
    end
end

function BuildProcess:resetTexture()
    if self.process then
        self.process:removeFromParent(true)
        self.process = nil
    end
    if self.ptype==1 then
        self.process = ui.sprite("images/proFillerHpOrange.png", {179, 23})
    else
        self.process = ui.sprite("images/proFillerHpGreen.png", {179, 23})
    end
    display.adapt(self.process, 2, 3)
    self.view:addChild(self.process)
    self.process:setProcess(true, self.value/self.max)
end

function BuildProcess:setValue(t)
    if t~=self.value then
        self.value = t
        self:resetValue()
    end
end

function BuildProcess:setLeftValue(t)
    local t1 = self.max - self.value
    if t1 ~= t then
        self.value = self.max - t
        self:resetValue()
    end
end

function BuildProcess:setMax(t)
    if self.max ~= t then
        self.max = t
        self:resetValue()
    end
end

function BuildProcess:resetValue()
    self.timeLabel:setString(StringManager.getTimeString(self.max-self.value))
    self.process:setProcess(true, self.value/self.max)
end

return BuildProcess
