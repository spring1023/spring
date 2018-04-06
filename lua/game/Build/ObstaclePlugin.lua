-- @Date: 2016/07/30
-- @Create By: lion
-- @Describe: 障碍物逻辑

local const = GMethod.loadScript("game.GameLogic.Const")

local ObstaclePlugin = {}

function ObstaclePlugin:addMenuButs(buts, item)
    if item=="remove" then
        if self.worklist then
            table.insert(buts, {key="cancel", callback=self.onCancelBuild, cp1=self})
            local cost = GameLogic.computeCostByTime(self.worklist[4]-GameLogic.getSTime())
            table.insert(buts, {key="acc", callback=self.onAccBuild, cp1=self,exts={rcost={text=cost}}})
        else
            local cr=GConst.Color.White
            local data = self.data
            local context = self.context
            if context:getRes(data.ctype) < data.cvalue then
                cr=GConst.Color.Red
            end
            table.insert(buts, {key="remove", callback = self.onBeginUpgrade, cp1=self, exts={rcost={text=self.data.cvalue,color=cr}, ricon={icon=self.data.ctype}}})
        end
    end
end

function ObstaclePlugin:getNextData()
    return self.data
end

function ObstaclePlugin:onBeginUpgrade()
    local ndata = self.data
    local checkSuccess = self:checkCost(ndata)
    if checkSuccess then
        local context = self.context
        context.buildData:removeObstacle(self, GameLogic.getSTime(), ndata)
        self:reloadBuilding()
        music.play("sounds/buildStart.wav")
        GameEvent.sendEvent(GameEvent.EventBuilderCome, self)
    end
end

return ObstaclePlugin
