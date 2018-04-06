
local SData = GMethod.loadScript("data.StaticData")
local MeltData = class()
local const = GMethod.loadScript("game.GameLogic.Const")
function MeltData:ctor(data)
    self.context = GameLogic.getUserContext()
    self.onAlchemy = data or {}
    self.gaEnery = self.context:getProperty(const.ProGaEnery)   --炼金能量
    self.gaStone = self.context:getProperty(const.ProGaStone)   --炼金石
    self.gaTime = self.context:getProperty(const.ProGaTime)     --能量时间
    local blv = self.context.buildData:getMaxLevel(8)
    if blv>0 then
        self.gaEnerySpeed = SData.getData("bdatas",40600,blv).produce
        self.gaEneryMax = SData.getData("bdatas",40600,blv).max
    else
        self.gaEnerySpeed = 0
        self.gaEneryMax = 0
    end
end

function MeltData:initGaEnery()
    local blv = self.context.buildData:getMaxLevel(8)
    if blv>0 then
        self.gaEnerySpeed = SData.getData("bdatas",40600,blv).produce
        self.gaEneryMax = SData.getData("bdatas",40600,blv).max
    else
        self.gaEnerySpeed = 0
        self.gaEneryMax = 0
    end
    local gaEnery = self.context:getProperty(const.ProGaEnery)
    local gaTime = self.context:getProperty(const.ProGaTime)
    local t = GameLogic.getSTime()-gaTime
    local tt = math.floor(t/360)
    gaEnery = gaEnery+tt*self.gaEnerySpeed
    gaTime = gaTime+tt*360
    if gaEnery>self.gaEneryMax then
        gaEnery = self.gaEneryMax
    end
    self.context:setProperty(const.ProGaEnery,gaEnery)
    self.context:setProperty(const.ProGaTime,gaTime)
end

return MeltData
