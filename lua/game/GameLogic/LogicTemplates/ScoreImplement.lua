local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local Base = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

local _set = Base.sset
local _setReader = Base.ssetReader

do
    -- 积分/段位通用组件；排序方式是1最小，N最大
    local ScoreImplement = {}
    Base.registerImplement("Score", ScoreImplement)

    function ScoreImplement:_static_load(config)
        _set(self, "scoreValue", config["score"])
        _setReader(self, "scoreTable", config["scoreTable"])
    end

    -- 根据当前值做一些预计算
    function ScoreImplement:_component_reload()
        self._scoreLevel = self:getScoreLevel(self._weak_ref.context:getNormalItem(self.scoreValue[1], self.scoreValue[2]))
    end

    -- 获取段位
    function ScoreImplement:getScoreLevel(score)
        local scoreLevel = 1
        local stable = self.scoreTable
        while true do
            local scoreItem = stable:getReadItem(scoreLevel)
            if not scoreItem or scoreItem["maxScore"] == 0 or scoreItem["maxScore"] >= score then
                break
            end
            scoreLevel = scoreLevel + 1
        end
        return scoreLevel
    end

    -- 根据分数获取段位信息
    function ScoreImplement:getLevelInfoByScore(score)
        local myLevel = self._scoreLevel
        if score then
            myLevel = self:getScoreLevel(score)
        end
        return self.scoreTable:getReadItem(myLevel)
    end

    -- 获取当前段位等级
    function ScoreImplement:getCurrentLevel()
        return self._scoreLevel
    end

    -- 获取最高段位
    function ScoreImplement:getMaxLevel()
        local datas = self.scoreTable:getItem()
        return #datas
    end

    -- 根据段位获取数据
    function ScoreImplement:getInfoByLevel(level)
        return self.scoreTable:getReadItem(level)
    end

    -- 获取下一段位积分
    function ScoreImplement:getNextLevelScore()
        local scoreItem = self.scoreTable:getReadItem(self._scoreLevel)
        local maxScore = scoreItem["maxScore"]
        if maxScore == 0 then
            return 0
        else
            return maxScore + 1
        end
    end

    -- 获取当前分数
    function ScoreImplement:getCurrentScore()
        return self._weak_ref.context:getNormalItem(self.scoreValue[1], self.scoreValue[2])
    end

    -- 改变积分并重新计算段位
    function ScoreImplement:changeScore(score)
        self._weak_ref.context:changeNormalItem(self.scoreValue[1], self.scoreValue[2], score)
        self._scoreLevel = self:getScoreLevel(self._weak_ref.context:getNormalItem(self.scoreValue[1], self.scoreValue[2]))
    end
end

do
    -- 排名通用组件；排序方式是1最小，N最大
    local RankImplement = {}
    Base.registerImplement("battle.rank", RankImplement)

    function RankImplement:_static_load(config)
        _set(self, "rankPro", config["rank"])
        _setReader(self, "rankTable", config["rankTable"])
    end

    -- 该值会随时改所以不预计算
    -- function RankImplement:_component_reload()
    --     self._rankLevel = self:getRankLevel(self._weak_ref.context:getProperty(self.rankPro))
    -- end

    -- 获取段位
    function RankImplement:getRankLevel(rank)
        if not rank then
            rank = self:getRank()
        end
        local rankLevel = 1
        local stable = self.rankTable
        while true do
            local rankItem = stable:getReadItem(rankLevel)
            if not rankItem or rankItem["maxRank"] <= rank and (rankItem["minRank"] == 0 or rankItem["minRank"] >= rank) then
                break
            end
            rankLevel = rankLevel + 1
        end
        return rankLevel
    end

    -- 感觉有点蛋疼，但是“一阶”是最高，但数值“1阶”是最低
    function RankImplement:getDisplayRankLevel(rank)
        if not rank then
            rank = self:getRank()
        end
        local rl = self:getRankLevel(rank)
        local stable = self.rankTable
        return (#stable:getItem()) - rl + 1
    end

    -- 根据分数获取段位信息
    function RankImplement:getCurrentData(rank)
        if not rank then
            rank = self:getRank()
        end
        local rlevel = self:getRankLevel(rank)
        return self.rankTable:getReadItem(rlevel)
    end

    -- 获取排名
    function RankImplement:getRank()
        return self._weak_ref.context:getProperty(self.rankPro)
    end

    -- 设置排名
    function RankImplement:setRank(rank)
        self._weak_ref.context:setProperty(self.rankPro, rank)
    end

    -- 获取下一段位积分
    -- function ScoreImplement:getNextLevelScore()
    --     local scoreItem = self.scoreTable:getReadItem(self._scoreLevel)
    --     local maxScore = scoreItem["maxScore"]
    --     if maxScore == 0 then
    --         return 0
    --     else
    --         return maxScore + 1
    --     end
    -- end

    -- -- 获取当前分数
    -- function ScoreImplement:getCurrentScore()
    --     return self._weak_ref.context:getNormalItem(self.scoreValue[1], self.scoreValue[2])
    -- end

    -- -- 改变积分并重新计算段位
    -- function ScoreImplement:changeScore(score)
    --     self._weak_ref.context:changeNormalItem(self.scoreValue[1], self.scoreValue[2], score)
    --     self._scoreLevel = self:getScoreLevel(self._weak_ref.context:getNormalItem(self.scoreValue[1], self.scoreValue[2]))
    -- end
end
