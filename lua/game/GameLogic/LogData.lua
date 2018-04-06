--进攻,防守日志和收件箱数据
local LogData = class()

function LogData:ctor()
    self.datas={["atklog"]={},["deflog"]={},["inbox"]={}}
    self.alogMaxL=0
    self.dlogMaxL=0
    self.boxMaxL=0
    self.openIndex=1
    self.atklogNotSeedNum=0
    self.deflogNotSeedNum=0
    self.emailNotSeedNum=0
    local uid=GameLogic.getUserContext().uid
    local sid=GameLogic.getUserContext().sid or 1
    self.eKey="email_" .. uid .."_".. sid
    self.alKey="atklog_" .. uid .."_".. sid
    self.dlKey="deflog_" .. uid .."_".. sid
    self.isFirstGetUserEmail=true
    self.lockEmail = false
end

function LogData:init()
    -- GMethod.schedule(Handler(self.update, self), 1, false)
end

function LogData:update(diff)
    local dtime = const.EmailRequestTime*60
    if not self.pollTime then
        self.pollTime = 0
        self:getLogDatas(true)
    end
    if self.lockEmail then
        return
    end
    if self.inSpecialMode then
        dtime = self.inSpecialMode[1]
    end
    self.pollTime = self.pollTime+diff
    if self.pollTime >= dtime then
        self.pollTime = 0
        self:getEmailDatas()
        if self.inSpecialMode then
            table.remove(self.inSpecialMode, 1)
            if not self.inSpecialMode[1] then
                self.inSpecialMode = nil
            end
        end
    end
end

function LogData:getLogDatas(isFirst)
    local logMaxId=0
    if GEngine.getConfig(self.alKey) then--本地已存在
        self.datas["atklog"] = json.decode(GEngine.getConfig(self.alKey))
        if GameLogic.isEmptyTable(self.datas["atklog"]) then
            self.datas["atklog"] = {}
        end
        self.alogMaxL=#self.datas["atklog"]
        if self.alogMaxL>0 then
            logMaxId=self.datas["atklog"][1].id--倒序后
        end
        if isFirst then
            for i=1,self.alogMaxL do
                if not self.datas["atklog"][i].isSeed then
                    self.atklogNotSeedNum=self.atklogNotSeedNum+1
                end
            end
        end
    end
    if GEngine.getConfig(self.dlKey) then--本地已存在
        self.datas["deflog"] = json.decode(GEngine.getConfig(self.dlKey))
        if GameLogic.isEmptyTable(self.datas["atklog"]) then
            self.datas["atklog"] = {}
        end
        self.dlogMaxL=#self.datas["deflog"]
        if self.dlogMaxL>0 and logMaxId<self.datas["deflog"][1].id then
            logMaxId=self.datas["deflog"][1].id
        end
        if isFirst then
            for i=1,self.dlogMaxL do
                if not self.datas["deflog"][i].isSeed then
                    self.deflogNotSeedNum=self.deflogNotSeedNum+1
                end
            end
        end
    end

    _G["GameNetwork"].request("getPvpReport",{getpvpreport={logMaxId}},function(isSuc,data)
        if isSuc then
            --print_r(data)
            --"atklog": [[1010, ["", 12, 0, "", 0], 100, [], 1461118532, 0, 3, 26, 100, 254]]
            --atklog [[uid,[名字,等级,当前分数,联盟名,联盟图标],摧毁度,[出战英雄id],攻打时间,是否复仇,星星,获取分数,获取金币,战报id]]

            local addL1=#data["atklog"]
            local addL2=#data["deflog"]
            self.alogMaxL=self.alogMaxL+addL1
            self.dlogMaxL=self.dlogMaxL+addL2

            --进攻
            for i=1,math.floor(addL1/2) do--倒序一下
                local da=data["atklog"][i]
                data["atklog"][i]=data["atklog"][addL1-i+1]
                data["atklog"][addL1-i+1]=da
            end

            for i=addL1,1,-1 do
                local da=data["atklog"][i]
                local tab={isSeed=false,uid=da[1],isRe=da[6],id=da[10],tname=da[2][1],plv=da[2][2],tscore=da[2][3],cname=da[2][4],ftag=da[2][5],destroy=da[3],slist=da[4],ttime=da[5],stars=da[7],gsc=da[8],gold=da[9]}
                self.atklogNotSeedNum=self.atklogNotSeedNum+1
                table.insert(self.datas["atklog"],1,tab)
            end

            --防守
            for i=1,math.floor(addL2/2) do--倒序一下
                local da=data["deflog"][i]
                data["deflog"][i]=data["deflog"][addL2-i+1]
                data["deflog"][addL2-i+1]=da
            end

            for i=addL2,1,-1 do
                local da=data["deflog"][i]
                local tab={isSeed=false,uid=da[1],isRe=da[6],id=da[10],tname=da[2][1],plv=da[2][2],tscore=da[2][3],cname=da[2][4],ftag=da[2][5],destroy=da[3],slist=da[4],ttime=da[5],stars=da[7],gsc=da[8],gold=da[9]}
                self.deflogNotSeedNum=self.deflogNotSeedNum+1
                table.insert(self.datas["deflog"],1,tab)
            end

            --超过99删除
            local length=self.alogMaxL
            if length>const.LogMaxLength then
                for i=1,length-const.LogMaxLength do
                    if not self.datas["atklog"][self.alogMaxL].isSeed then
                        self.atklogNotSeedNum=self.atklogNotSeedNum-1
                    end
                    table.remove(self.datas["atklog"],self.alogMaxL)
                    self.alogMaxL=self.alogMaxL-1
                end
            end
            local length=self.dlogMaxL
            if length>const.LogMaxLength then
                for i=1,length-const.LogMaxLength do
                    if not self.datas["deflog"][self.dlogMaxL].isSeed then
                        self.deflogNotSeedNum=self.deflogNotSeedNum-1
                    end
                    table.remove(self.datas["deflog"],self.dlogMaxL)
                    self.dlogMaxL=self.dlogMaxL-1
                end
            end
            --战报,存储到本地
            GEngine.setConfig(self.alKey, json.encode(self.datas["atklog"]),true)
            GEngine.setConfig(self.dlKey, json.encode(self.datas["deflog"]),true)
        end
    end)
end

function LogData:setReceiveSpecial(specialMode)
    self.inSpecialMode = specialMode
end

--获取邮件数据，并存入本地
function LogData:getEmailDatas()
    if self.lockEmail then
        return
    end
    self.lockEmail = true
    local requestID=0
    if self.isFirstGetUserEmail and GEngine.getConfig(self.eKey)then
        requestID=1
        self.oldEmailData=json.decode(GEngine.getConfig(self.eKey))
        GEngine.setConfig(self.eKey, json.encode({}),true)--清空本地数据
    end

    local boxMaxId=0
    if GEngine.getConfig(self.eKey) then--本地已存在
        self.datas["inbox"]=json.decode(GEngine.getConfig(self.eKey))
        self.boxMaxL=#self.datas["inbox"]
        if self.boxMaxL>0 then
            boxMaxId=self.datas["inbox"][1].id
        end
    end
    _G["GameNetwork"].request("getUserEmail",{getuseremail={boxMaxId,requestID}},function(isSuc,data)
        self.lockEmail = false
        if isSuc then
            --print_r(data)
            --{"email": [[1, 1,-2, 1003, 2, 0, 2, 2, "", 0]]}
            --邮件id，rid,发件人，收件人id，图标，发送时间，内容，标题，物品奖励，是否领取
            for i,newData in ipairs(data["email"]) do--检测重复的id
                local newId=newData[1]
                for j,da in ipairs(self.datas["inbox"]) do
                    if newId==da.id then
                        table.remove(data["email"],i)
                        break
                    end
                end
            end
            local addL=#data["email"]--新数据长度
            self.boxMaxL=self.boxMaxL+addL
            if addL > 0 and self.inSpecialMode then
                self.inSpecialMode = nil
            end

            for i=1,math.floor(addL/2) do--倒序一下
                local da=data["email"][i]
                data["email"][i]=data["email"][addL-i+1]
                data["email"][addL-i+1]=da
            end

            for i=addL,1,-1 do
                local da=data["email"][i]
                local tab
                local iconType = da[4]
                --类型转化为删除邮件
                if iconType == 1 or iconType == 2 or iconType == 3 then
                    iconType=4
                end
                -- eid,rid,tid,hed,etime,cont,title,sender,items,isaward
                if da[4]==6 then--联盟战邮件
                   tab={isUnionEmail=true,id=da[1],rid=da[2],uid=da[3],icon=2,time=da[5],cont=json.decode(da[6]),title=json.decode(da[7]),tname=da[8],reward=json.decode(da[9]),recevice=da[10]}
                elseif da[2]==20 then--礼包码邮件
                   tab={isPackCodeEmail=true,id=da[1],rid=da[2],uid=da[3],icon=iconType,time=da[5],cont=json.decode(da[6]),title=json.decode(da[7]),tname=da[8],reward=json.decode(da[9]),recevice=da[10]}
                elseif da[2] == 21 then --淘汰赛奖励邮件
                    tab = {isKnockOutReward = true, id = da[1], rid = da[2], uid = da[3], icon = iconType, time = da[5], cont = json.decode(da[6]), title=json.decode(da[7]),tname=da[8],reward=json.decode(da[9]),recevice=da[10]}
                elseif da[2] == 22 then
                    tab = {isKnockOutGamble = true, id = da[1], rid = da[2], uid = da[3], icon = iconType, time = da[5], cont = json.decode(da[6]), title=json.decode(da[7]),tname=da[8],reward=json.decode(da[9]),recevice=da[10]}
                else
                    tab={id=da[1],rid=da[2],uid=da[3],icon=iconType,time=da[5],cont=json.decode(da[6]),title=json.decode(da[7]),tname=da[8],reward=json.decode(da[9]),recevice=da[10]}
                end
                if self.isFirstGetUserEmail and self.oldEmailData then
                    local isNew=true
                    for j,oldData in ipairs(self.oldEmailData) do
                        if tab.id==oldData.id then
                            if oldData.isSeed then
                                tab.isSeed=true
                            else
                                tab.isSeed=false
                                self.emailNotSeedNum=self.emailNotSeedNum+1
                            end
                            isNew=false
                            break
                        end
                    end
                    --是新增的
                    if isNew then
                        tab.isSeed=false
                        self.emailNotSeedNum=self.emailNotSeedNum+1
                    end
                else
                    tab.isSeed=false
                    self.emailNotSeedNum=self.emailNotSeedNum+1
                end
                table.insert(self.datas["inbox"],1,tab)
            end
            local length=self.boxMaxL
            if length>const.LogMaxLength then--超过99删除
                for i=1,length-const.LogMaxLength do
                    if not self.datas["inbox"][self.boxMaxL].isSeed then
                        self.emailNotSeedNum=self.emailNotSeedNum-1
                    end
                    table.remove(self.datas["inbox"],self.boxMaxL)
                    self.boxMaxL=self.boxMaxL-1
                end
            end
            self.boxMaxL=#self.datas["inbox"]
            GEngine.setConfig(self.eKey, json.encode(self.datas["inbox"]),true)--数据存在本地
            self.isFirstGetUserEmail=false
        end
    end)
end

function LogData:getOpenIndex()
    if self.emailNotSeedNum>0 then
        self.openIndex=3
    end
    if self.atklogNotSeedNum>0 then
        self.openIndex=2
    end
    if self.deflogNotSeedNum>0 then
        self.openIndex=1
    end
    return self.openIndex
end

--数字提醒包括新增数据及未读数据
function LogData:getRedNum()
    local num=self.deflogNotSeedNum+self.emailNotSeedNum
    return num
end

function LogData:changeRedNum(key)
    if key=="atklog" then
        self.atklogNotSeedNum=0
    elseif key=="deflog" then
        self.deflogNotSeedNum=0
    elseif key=="email" then
        if self.emailNotSeedNum>0 then
            self.emailNotSeedNum=self.emailNotSeedNum-1
        end
    end
end

return LogData
