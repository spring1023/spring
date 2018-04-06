local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local BuildData = class()

function BuildData:ctor(context)
	self.udata = context
    self.obsNum = 0
end

function BuildData:destroy()
    self.udata = nil

    self.blayouts = nil
    self.oblayouts = nil
    self.bexts = nil
    self.bbuilds = nil
    self.bnums = nil
    self.blevels = nil
    self.btotal = nil
    self.obsNum = nil
    self.bmax = nil

    self.clayouts = nil
    self.cexts = nil
    self.workList = nil
    self.workListBidx = nil
    self.armors = nil
end

function BuildData:loadData(data)
    local bbuilds = {}
    local blayouts = {{},{},{}}
    local oblayouts = {{},{},{}}
    local bexts = {}

    local bnums = {}
    local blevels = {}
    local bmax, btotal = 0, 0

    for _, build in ipairs(data.builds) do
        bbuilds[build[1]] = {build[2], build[3]}
        bnums[build[2]] = (bnums[build[2]] or 0)+1
        btotal = btotal+1
        if build[1]>bmax then
            bmax = build[1]
        end
        if not blevels[build[2]] or blevels[build[2]]<build[3] then
            blevels[build[2]] = build[3]
        end
    end
    for _, layout in ipairs(data.layouts) do
        blayouts[1][layout[1]] = {layout[2], layout[3]}
        blayouts[2][layout[1]] = {layout[4], layout[5]}
        blayouts[3][layout[1]] = {layout[6], layout[7]}
        oblayouts[1][layout[1]] = {layout[2], layout[3]}
        oblayouts[2][layout[1]] = {layout[4], layout[5]}
        oblayouts[3][layout[1]] = {layout[6], layout[7]}
    end
    for _, ext in ipairs(data.bexts) do
        bexts[ext[1]] = {ext[2], ext[3]}
    end
    self.blayouts = blayouts
    self.oblayouts = oblayouts
    self.bexts = bexts
    self.bbuilds = bbuilds
    self.bnums = bnums
    self.blevels = blevels
    self.btotal = btotal
    self.bmax = bmax

    self.clayouts = {}
    self.cexts = {}

    local workList = {}
    local workListBidx = {}
    local boostListBidx = {}
    for _, wl in ipairs(data.wlist) do
        workList[wl[1]] = wl
        if wl[5]>0 then
            if wl[2]==1 then
                workListBidx[wl[5]] = wl
            elseif wl[2]==2 then
                boostListBidx[wl[5]] = wl
            end
        end
    end
    self.workList = workList
    self.workListBidx = workListBidx
    self.boostListBidx = boostListBidx

    local armors = {}
    for _, armor in ipairs(data.armors) do
        armors[armor[1]] = armor[2]
    end
    self.armors = armors
end

function BuildData:getBuildWorkList()
	return self.workListBidx
end

function BuildData:getBoostWorkList()
    return self.boostListBidx
end

function BuildData:addWorkList(wid, stime, totalTime, bidx)
    local wl = {wid, 1, stime, stime+totalTime, bidx}
    self.workList[wid] = wl
    self.workListBidx[bidx] = wl
    return wl
end

function BuildData:addBoostList(wid, stime, totalTime, bidx)
    local wl = {wid, 2, stime, stime+totalTime, bidx}
    self.workList[wid] = wl
    self.boostListBidx[bidx] = wl
    return wl
end

function BuildData:removeWorkList(wl)
    self.workList[wl[1]] = nil
    if wl[5]>0 then
        if wl[2]==1 then
            self.workListBidx[wl[5]] = nil
        elseif wl[2]==2 then
            self.boostListBidx[wl[5]] = nil
        end
    end
end

function BuildData:getBuildNum(bid)
    return self.bnums[bid] or 0
end

function BuildData:getMaxLevel(bid)
    return self.blevels[bid] or 0
end

function BuildData:getTownLevel()
    return self.blevels[const.Town] or 0
end

function BuildData:getNextBidx(bid)
    local builds = self.bbuilds
    if self.btotal<self.bmax and bid~=3 then
        for i=1, self.bmax do
            if not builds[i] then
                return i
            end
        end
    end
    return self.bmax+1
end

function BuildData:getNextWidx()
	for i=1, 100 do
		if not self.workList[i] then
			return i
		end
	end
	return nil
end

function BuildData:getSceneBuilds()
    if self.rbuilds then
        return self.rbuilds
    end
    local rbuilds = {}
    local blayouts = self.blayouts
    local bexts = self.bexts
    local armors = self.armors
    local wls = self.workListBidx
    local bls = self.boostListBidx
    local layoutId = self.udata:getInfoItem(const.InfoLayout)
    self.obsNum = 0
    local rbuild,blayout
    local rgid
    for bidx, build in pairs(self.bbuilds) do
        blayout = blayouts[layoutId][bidx]
        rbuild = Build.new(build[1], build[2])
        rbuild.group = 1
        rbuild.context = self.udata
        rbuild.id = bidx
        rbuild.extData = bexts[bidx]
        rbuild.armor = armors[bidx]
        rbuild.worklist = wls[bidx]
        rbuild.boostlist = bls[bidx]
        rbuild.initGrid = blayout
        rbuilds[bidx] = rbuild
        if rbuild.info.btype == 6 then
            self.obsNum = self.obsNum + 1
        end
    end
    self.rbuilds = rbuilds
    return rbuilds
end

function BuildData:buyNewBuild(build, wtime)
    local data = build.data
    local bid = build.bid
    local blevel = build.level
    local bidx = self:getNextBidx(bid)
    local layoutId = self.udata:getInfoItem(const.InfoLayout)
    local gx = build.vstate.gx
    local gy = build.vstate.gy
    local wid = 0
    if data.ctime>0 then
        wid = self:getNextWidx()
    end
    if build:isStatue() then
        wid = blevel+build.extData[1]*100
        wtime = build.extData[2]
    end

    if data.costitem then
        self.udata:changeItem(const.ItemBuild, data.costitem, -1)
    else
        self.udata:changeRes(data.ctype, -data.cvalue)
    end
    local cmd = {const.CmdBuyBuild,bidx,bid,layoutId,gx,gy,wtime,wid}
    self.udata:addCmd(cmd)

    build.id = bidx
    if data.ctime>0 then
        build.worklist = self:addWorkList(wid, wtime, data.ctime, bidx)
        self.udata:changeRes(const.ResBuilder, -1)
    else
        if data.exp and data.exp>0 then
            self.udata:addExp(data.exp)
        end
        if (self.blevels[bid] or 0)<1 then
            self.blevels[bid] = 1
            local achieveData = self.udata.achieveData
            -- achieveData:finish(1)
            achieveData:finish(const.ActTypeBuildLevelUp)
        end

        --对应建筑建造完成时
        local context = self.udata
        local stepSet = {[2]=14, [5]=24, [4]=34, [6]=44, [8]=64}
        local step = stepSet[bid]
        if stepSet then
            context.guideOr:setStep(step)
        end
    end
    self.bbuilds[bidx] = {bid, blevel}
    for i=1, 3 do
        self.blayouts[i][bidx] = {0, 0}
        self.oblayouts[i][bidx] = {0, 0}
    end
    self.blayouts[layoutId][bidx] = {gx, gy}
    self.oblayouts[layoutId][bidx] = {gx, gy}
    self.btotal = self.btotal+1
    if bidx>self.bmax then
        self.bmax = bidx
    end
    self.bnums[bid] = (self.bnums[bid] or 0)+1
    self.bexts[bidx] = build.extData
    GameEvent.sendEvent("refreshStoreRedNum")
end

function BuildData:updateBuildLevel(build)
    local bidx = build.id
    local blevel = build.level
    self.bbuilds[bidx][2] = blevel
    local bid = build.bid
    if build.data.exp and build.data.exp>0 then
        self.udata:addExp(build.data.exp)
    end

    if (self.blevels[bid] or 0)<blevel then
        self.blevels[bid] = blevel
        local achieveData = self.udata.achieveData
        -- achieveData:finish(1)
        achieveData:finish(const.ActTypeBuildLevelUp)
    end
    GameEvent.sendEvent("refreshStoreRedNum")
end

function BuildData:removeBuild(build)
    local bidx = build.id
    self.bbuilds[bidx] = nil
    for i=1, 3 do
        self.blayouts[i][bidx] = nil
        self.oblayouts[i][bidx] = nil
    end
    self.clayouts[bidx] = nil
    self.bexts[bidx] = nil
    self.btotal = self.btotal-1
    if build.info.btype == 6 then
        self.obsNum = self.obsNum - 1
    end
    if bidx==self.bmax then
        self.bmax = self.bmax-1
    end
    local bid = build.bid
    self.bnums[bid] = (self.bnums[bid] or 1)-1
    if self.rbuilds and self.rbuilds[bidx] then
        self.rbuilds[bidx] = nil
    end
    GameEvent.sendEvent("refreshStoreRedNum")
end

function BuildData:removeStatue(build)
    self.udata:addCmd({const.CmdRemoveBuild,build.id})
    self:removeBuild(build)
    GameEvent.sendEvent("refreshStoreRedNum")
end

function BuildData:sellBuild(build)
    self.udata:addCmd({const.CmdSellBuild,build.id})
    self:removeBuild(build)
    GameEvent.sendEvent("refreshStoreRedNum")
end

function BuildData:beginBoostBuild(build, stime, totalTime, cost)
    local bidx = build.id
    local wid = self:getNextWidx()
    self.udata:addCmd({const.CmdBoostBuild, bidx, stime, wid})

    self.udata:changeRes(const.ResCrystal, -cost)
    GameLogic.statCrystalCost("建筑生产提速消耗",const.ResCrystal, -cost)
    build.boostlist = self:addBoostList(wid, stime, totalTime, bidx)
    GameEvent.sendEvent("refreshStoreRedNum")
end

function BuildData:boostOverBuild(build, stime)
    local bidx = build.id
    local bl = build.boostlist
    self:removeWorkList(bl)
    build.boostlist = nil
    self.udata:addCmd({const.CmdBoostOver, bidx, stime, bl[1]})
    GameEvent.sendEvent("refreshStoreRedNum")
end

function BuildData:beginUpgradeBuild(build, stime, data)
    local bidx = build.id
    local wid = 0
    if data.ctime>0 then
        wid = self:getNextWidx()
    end
    self.udata:changeRes(data.ctype, -data.cvalue)
    self.udata:addCmd({const.CmdUpgradeBuild, bidx, stime, wid})
    if data.ctime>0 then
        self.udata:changeRes(const.ResBuilder, -1)
        build.worklist = self:addWorkList(wid, stime, data.ctime, bidx)
    else
        self:updateBuildLevel(build)
    end
end

function BuildData:removeObstacle(build, stime, data)
    local bidx = build.id
    local wid = self:getNextWidx()
    self.udata:changeRes(data.ctype, -data.cvalue)
    self.udata:changeRes(const.ResBuilder, -1)
    self.udata:addCmd({const.CmdRemoveObstacle, bidx, stime, wid})
    build.worklist = self:addWorkList(wid, stime, data.ctime, bidx)
end

function BuildData:finishRemoveObstacle(build, stime, data)
    local bidx = build.id
    local wl = build.worklist
    self.udata:addCmd({const.CmdFinishRemove, bidx, stime})
    self.udata:changeRes(const.ResBuilder, 1)
    self:removeWorkList(wl)
    build.worklist = nil
    self:removeBuild(build)
    self.udata:changeProperty(const.ProRmBlock, 1)
    local achieveData = GameLogic.getUserContext().achieveData
    achieveData:finish(const.ActTypeRmBlock,self.udata:getProperty(const.ProRmBlock))

    local produce = data.produce
    if type(produce[1]) == "table" then
        local ridx = self.udata:nextRandom(KTLen(produce)) + 1
        produce = produce[ridx]
    end
     return produce
end

function BuildData:initObstacle(build, stime, actId)
    local cmd
    if not actId then
        local otime = self.udata:getProperty(const.ProObsTime)
        if stime then
            otime = otime + math.ceil((stime - otime) / 28800) * 28800
        else
            otime = otime + 28800
        end
        self.udata:setProperty(const.ProObsTime, otime)
        cmd = {const.CmdInitObstacle, otime}
    else
        cmd = {const.CmdInitObstacle, stime, actId}
    end
    if build then
        if not actId then
            self.obsNum = self.obsNum + 1
        end
        local bid = build.bid
        local blevel = build.level
        local bidx = self:getNextBidx(bid)
        local layoutId = self.udata:getInfoItem(const.InfoLayout)
        local gx = build.vstate.gx
        local gy = build.vstate.gy

        cmd[3] = bidx
        cmd[4] = bid
        cmd[5] = blevel
        cmd[6] = layoutId
        cmd[7] = gx
        cmd[8] = gy
        cmd[9] = actId

        build.id = bidx
        self.bbuilds[bidx] = {bid, blevel}
        for i=1, 3 do
            self.blayouts[i][bidx] = {0, 0}
            self.oblayouts[i][bidx] = {0, 0}
        end
        self.blayouts[layoutId][bidx] = {gx, gy}
        self.oblayouts[layoutId][bidx] = {gx, gy}
        self.btotal = self.btotal+1
        if bidx>self.bmax then
            self.bmax = bidx
        end
        self.bnums[bid] = (self.bnums[bid] or 0)+1
    end
    self.udata:addCmd(cmd)
end

function BuildData:upgradeBuildOver(build, stime, data)
    local bidx = build.id
    local wl = build.worklist
    self.udata:addCmd({const.CmdUpgradeBuildOver, bidx, stime, wl[1]})

    self.udata:changeRes(const.ResBuilder, 1)
    self:updateBuildLevel(build)
    self:removeWorkList(wl)
    build.worklist = nil
end

function BuildData:cancelBuild(build, stime, data)
    self.udata:addCmd({const.CmdCancelBuild, build.id, stime})

    self.udata:changeResWithMax(data.ctype, math.floor(data.cvalue/2))
    self.udata:changeRes(const.ResBuilder, 1)
    self:removeWorkList(build.worklist)
    build.worklist = nil
    if build.level==0 then
        self:removeBuild(build)
    end
    GameEvent.sendEvent("refreshStoreRedNum")
end

function BuildData:accBuild(build, stime, cost)
    self.udata:addCmd({const.CmdAccBuild, build.id, stime})
    local wl = build.worklist
    local total = wl[4]-wl[3]
    wl[3] = stime-total
    wl[4] = stime
    self.udata:changeRes(const.ResCrystal, -cost)
    GameLogic.statCrystalCost("建筑升级立即完成消耗",const.ResCrystal, -cost)
end

function BuildData:accBuildByVip(build)
    self.udata:addCmd({const.CmdAccBuildItem, build.id, 0})
    local wl = build.worklist
    if wl and wl[4]>GameLogic.getSTime() then
        local value = 3600
        wl[3] = wl[3]-value
        wl[4] = wl[4]-value
        return true
    end
end

function BuildData:accBuildByItem(build, itemId)
    self.udata:addCmd({const.CmdAccBuildItem, build.id, itemId})
    if itemId>0 then
        self.udata:changeItem(const.ItemAccObj, itemId, -1)
        local wl = build.worklist
        if wl and wl[4]>GameLogic.getSTime() then
            local value = SData.getData("property",const.ItemAccObj,itemId).value
            wl[3] = wl[3]-value
            wl[4] = wl[4]-value
            return true
        end
    end
end

function BuildData:collectResource(build, stime, get, oext1, oext2)
    self.udata:changeResWithMax(build.extSetting, get)
    self.udata:addCmd({const.CmdCollectRes, build.id, stime, oext1, oext2, get})
end

function BuildData:upgradeBuildArmor(build, cost)
    local bidx = build.id
    self.udata:changeRes(const.ResZhanhun, -cost)
    self.armors[bidx] = (self.armors[bidx] or 0)+1
    build.armor = self.armors[bidx]
    self.udata:addCmd({const.CmdUpgradeArmor, bidx})
end

function BuildData:changeBuildLayout(bidx, gix, giy)
    local layoutId = self.udata:getInfoItem(const.InfoLayout)
    local layout = self.blayouts[layoutId][bidx]
    if layout then
        layout[1] = gix
        layout[2] = giy
        self.clayouts[bidx] = layout
    end
end

function BuildData:dumpLayoutChanges()
    local layoutId = self.udata:getInfoItem(const.InfoLayout)
    local ret = {const.CmdBatchLayouts, layoutId}
    local idx = 2
    for bidx, layout in pairs(self.clayouts) do
        local olayout = self.oblayouts[layoutId][bidx]
        if not olayout or olayout[1]~=layout[1] or olayout[2]~=layout[2] then
            ret[idx+1] = bidx
            ret[idx+2] = layout[1]
            ret[idx+3] = layout[2]
            idx = idx+3
            olayout[1] = layout[1]
            olayout[2] = layout[2]
        end
    end
    if idx>2 then
        self.udata:addCmd(ret)
        self.clayouts = {}
    end
end

function BuildData:getBuild(id)
    local scene = GMethod.loadScript("game.View.Scene")
    for k,v in pairs(scene.builds) do
        if v.bid == id then
            return v
        end
    end
end

function BuildData:getBuildByIdx(idx)
    local scene = GMethod.loadScript("game.View.Scene")
    for k,v in pairs(scene.builds) do
        if v.id == idx then
            return v
        end
    end
end

--2防御建筑    3功能建筑  8神像  9资源建筑
function BuildData:reloadCanBuildNum()
    local bdata, binfo, blv, bnum
    local tid = 1
    local tlevel = self:getMaxLevel(tid)
    local bsetting
    local context = self.udata
    local config = GMethod.loadConfig("configs/store.json").bids
    local btype = {2,3,8,9}
    self.canBuildNum = {}
    for i,tp in ipairs(btype) do
        local bids = config[tostring(tp)]
        for i,bid in ipairs(bids) do
            local canNum = 0
            if bid>=181 and bid<=185 then--神像按10个等级配置的
                if self:getBuildNum(bid)==0 then
                    local config = SData.getData("AllRankConfig",bid-180)
                    if context.rankList[bid][2]<GameLogic.getSTime() then
                        context.rankList[bid][1] = nil
                    end
                    local rank = context.rankList[bid][1]
                    rank = rank and (rank+1)
                    local blv = 0
                    for i,v in ipairs(config) do
                        if rank and v.minrk<=rank and rank<=v.maxrk then
                            blv = v.build
                        end
                    end
                    for i=1,10 do
                        if i == blv then
                            canNum = 1
                        end
                    end
                end
            elseif bid == 186 or bid == 187 then
                local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
                if KnockMatchData:canAddStatue(bid) then
                    canNum = 1
                end
            elseif bid == 188 then
                local YouthDayData = GMethod.loadScript("game.GameLogic.YouthDayData")
                if YouthDayData:canAddStatue(bid) then
                    canNum = 1
                end
            elseif bid ~= 11 then
                blv = 1
                bnum = self:getBuildNum(bid)
                bsetting = BU.getBSetting(bid)
                binfo = SData.getData("binfos", bsetting.bdid)
                if bsetting.numAsLevel then
                    blv = bnum+1
                    if blv>binfo.maxNum then
                        blv = binfo.maxNum
                    end
                end
                bdata = SData.getData("bdatas", bsetting.bdid, blv)
                local max=binfo.levels[tlevel]
                canNum = max-bnum
            end
            if not self.canBuildNum[tp] then
                self.canBuildNum[tp] = canNum
            else
                self.canBuildNum[tp] = self.canBuildNum[tp]+canNum
            end
        end
    end
end

function BuildData:getCanBuildNum(btype)
    if not btype then
        local count = 0
        for k,v in pairs(self.canBuildNum) do
            count = count+v
        end
        return count
    else
        return self.canBuildNum[btype]
    end
end

function BuildData:getBuildLayout(lid,build)
    local bidx = build.id
    return self.blayouts[lid][bidx]
end

return BuildData
