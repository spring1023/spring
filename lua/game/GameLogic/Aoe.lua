local Aoe = {}

function Aoe.circlePoint(pointTab,target,radius)
    local result = {}
    for k,v in ipairs(pointTab) do
        if (v[1]-target[1])*(v[1]-target[1])+(v[2]-target[2])*(v[2]-target[2])<=(radius+v[3])^2 then
            table.insert(result,v)
        end
    end
    return result
end

function Aoe.sectorPoint(pointTab,startPoint,radius,angle,target)
    local direction
    if type(target) == "number" then
        direction = target
    else
        direction = math.deg(math.atan((target[2]-startPoint[2])/(target[1]-startPoint[1])))
        if target[2]-startPoint[2]<0 and target[1]-startPoint[1]<0 then
            direction = direction + 180
        end
        if target[2]-startPoint[2]>0 and target[1]-startPoint[1]<0 then
            direction = direction + 180
        end
    end

    local result = {}
    local angle1 = direction-angle/2
    local angle2 = direction+angle/2
    angle1 = angle1<0 and angle1+360 or angle1
    angle1 = angle1>360 and angle1-360 or angle1
    angle2 = angle2<0 and angle2+360 or angle2
    angle2 = angle2>360 and angle2-360 or angle2
    for k,v in ipairs(pointTab) do
        local isMeet1 = false
        local isMeet2 = false
        if math.sqrt((v[1]-startPoint[1])*(v[1]-startPoint[1])+(v[2]-startPoint[2])*(v[2]-startPoint[2]))-v[3]<=radius then 
            if (0<=angle1 and angle1<90) or (270<angle1 and angle1<=360) then
                if (((v[1]-startPoint[1])*math.tan(math.rad(angle1))))<=((v[2]-startPoint[2]))+math.abs(v[3]/math.cos(math.rad(angle1))) then
                    isMeet1 = true
                end
            elseif angle1==90 then
                if v[1]<=startPoint[1]+v[3] then
                    isMeet1 =true
                end    
            elseif angle1==270 then
                if v[1]>=startPoint[1]-v[3] then
                    isMeet1 = true
                end    
            else
                if ((v[1]-startPoint[1])*math.tan(math.rad(angle1)))>=(v[2]-startPoint[2])-math.abs(v[3]/math.cos(math.rad(angle1))) then
                    isMeet1 = true
                end
            end

            if (0<=angle2 and angle2<90) or (270<angle2 and angle2<=360) then
                if ((v[1]-startPoint[1])*math.tan(math.rad(angle2)))>=(v[2]-startPoint[2])-math.abs(v[3]/math.cos(math.rad(angle2))) then
                    isMeet2 = true
                end
            elseif angle2==90 then
                if v[1]>=startPoint[1]-v[3] then
                    isMeet2 =true
                end    
            elseif angle2==270 then
                if v[1]<=startPoint[1]+v[3] then
                    isMeet2 = true
                end 
            else
                if ((v[1]-startPoint[1])*math.tan(math.rad(angle2)))<=(v[2]-startPoint[2])+math.abs(v[3]/math.cos(math.rad(angle2))) then
                    isMeet2 = true
                end
            end

            if isMeet1 and isMeet2 then
                table.insert(result,v)
            end

        end
    end
    return result
end

function Aoe.line(pointTab,startPoint,long,wide,target)
    local sx,sy,tx,ty = startPoint[1],startPoint[2],target[1],target[2]
    local result = {}
    wide = wide/2
    if sy == ty then
        for k,v in ipairs(pointTab) do
            if sx<tx then
                if sx<=v[1]+v[3] and v[1]-v[3]<=sx+long and sy-wide<=v[2]+v[3] and v[2]-v[3]<=sy+wide then
                    table.insert(result,v)
                end
            else
                if sx-long<=v[1]+v[3] and v[1]-v[3]<=sx and sy-wide<=v[2]+v[3] and v[2]-v[3]<=sy+wide then
                    table.insert(result,v)
                end
            end
        end
    elseif sx == tx then
        for k,v in ipairs(pointTab) do
            if sy<ty then
                if sy<=v[2]+v[3] and v[2]-v[3]<=sy+long and sx-wide<=v[1]+v[3] and v[1]-v[3]<=sx+wide then
                    table.insert(result,v)
                end
            else
                if sy-long<=v[2]+v[3] and v[2]-v[3]<=sy and sx-wide<=v[1]+v[3] and v[1]-v[3]<=sx+wide then
                    table.insert(result,v)
                end
            end
        end
    else
        local d = (ty-sy)/(tx-sx)
        local a = sy-d*sx
        local rad = math.atan(d)
        local a1 = a-wide/math.cos(rad)
        local a2 = a+wide/math.cos(rad)
        local d2 = -1/d
        local rad2 = math.atan(d2)
        local a21 = sy-d2*sx
        local a22 = a21+long/math.cos(rad2)
        if sy>ty then
            a22 = a21-long/math.cos(rad2)
            a21,a22=a22,a21
        end

        
        for k,v in ipairs(pointTab) do
            if v[2]>=d*v[1]+a1-v[3]/math.cos(rad) and v[2]-v[3]/math.cos(rad)<=d*v[1]+a2 and v[2]>=d2*v[1]+a21-v[3]/math.cos(rad2) and v[2]-v[3]/math.cos(rad2)<=d2*v[1]+a22 then
                table.insert(result,v)
            end
        end    
    end
    return result
end

function Aoe.chain(pointTab,startPoint,maxDis,num)
    local result = {startPoint}
    local dump = {}
    local index = 1
    while index<=num do
        local isFind = false
        local disTemp = 100000
        local key = 0
        for k,v in ipairs(pointTab) do
            local dis = math.sqrt((v[1]-startPoint[1])*(v[1]-startPoint[1])+(v[2]-startPoint[2])*(v[2]-startPoint[2]))-startPoint[3]-v[3]
            if not dump[v] and dis<disTemp and dis<=maxDis then
                result[index] = v
                disTemp = dis
                key = k
                isFind = true
            end
        end
        if isFind then
            startPoint = result[index]
            dump[startPoint]=1
            index = index+1
        else
            break
        end
    end
    return result
end

_G["Aoe"] = Aoe
return Aoe
