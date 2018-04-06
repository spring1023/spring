
local SData = GMethod.loadScript("data.StaticData")
local SceneZombie={}

function SceneZombie.init(scene)
    if not scene.zombie then
        scene.zombie = {}
    end
    for i,v in ipairs(scene.zombie) do
        v:removeFromScene()
    end
    scene.zombie = {}
    SceneZombie.scene=scene
    SceneZombie.create_Up()
    SceneZombie.create_Down()
    SceneZombie.create_Left()
    SceneZombie.create_Right()
end

function SceneZombie.destory(scene)
    if scene.zombie then
        for i,v in ipairs(scene.zombie) do
            v:removeFromScene()
        end
        scene.zombie = {}
    end
end

local pos1={{343,2456},{639,2258},{810,2378},{553,2556}}
function SceneZombie.create_Up()

    SceneZombie.addZombie(1,902,pos1[1][1],pos1[1][2])
    SceneZombie.addZombie(1,902,pos1[2][1],pos1[2][2])
    SceneZombie.addZombie(1,902,490,2482)
    SceneZombie.addZombie(1,902,656,2384)
    SceneZombie.addZombie(1,902,pos1[3][1],pos1[3][2])
    SceneZombie.addZombie(1,903,pos1[4][1],pos1[4][2])

end

local pos2={{2729,271},{2884,120},{3810,840},{3663,963}}
function SceneZombie.create_Down()

    SceneZombie.addZombie(2,902,pos2[1][1],pos2[1][2])
    SceneZombie.addZombie(2,902,pos2[2][1],pos2[2][2])
    SceneZombie.addZombie(2,902,pos2[3][1],pos2[3][2])
    SceneZombie.addZombie(2,903,pos2[4][1],pos2[4][2])
end

local pos3={{271,309},{361,222},{778,521},{672,605}}
function SceneZombie.create_Left()

    SceneZombie.addZombie(3,902,pos3[1][1],pos3[1][2])
    SceneZombie.addZombie(3,902,pos3[2][1],pos3[2][2])
    SceneZombie.addZombie(3,902,pos3[3][1],pos3[3][2])
    SceneZombie.addZombie(3,903,pos3[4][1],pos3[4][2])
end

local pos4={{2508,2961},{2597,2890},{2794,3025},{2667,3026}}
function SceneZombie.create_Right()
    SceneZombie.addZombie(4,902,pos4[1][1],pos4[1][2])
    SceneZombie.addZombie(4,903,pos4[3][1],pos4[3][2])
end

function SceneZombie.addZombie(ID,id,x,y)
        local sinfo = clone(SData.getData("sinfos",id))
        sinfo.speed = sinfo.speed*0.5
        local params = {group = 1,state = AvtControlerState.ZOMBIE,person=PersonUtil.newPersonData(sinfo,{hp=10,atk=10,id=id,level=1})}
        
        local zombie = PersonUtil.C(params)
        local gx,gy = SceneZombie.scene.map.convertToGrid(x,y)
        zombie:addToScene(SceneZombie.scene,gx,gy)
        if ID==1 then
            zombie.changjing_pos=pos1
        elseif ID==2 then
            zombie.changjing_pos=pos2
            zombie.avater.view:setScale(1.1)
        elseif ID==3 then
            zombie.changjing_pos=pos3
            zombie.avater.view:setScale(1.1)
        elseif ID==4 then
            zombie.changjing_pos=pos4
        end
        table.insert(SceneZombie.scene.zombie,zombie)
end

function SceneZombie.fanwei_jiance(n,p,point)
    if n~=4 then
        return
    end

    local p1,p2,p3,p4=p[1],p[2],p[3],p[4]

    local bian12=math.sqrt((p1[1]-p2[1])^2+(p1[2]-p2[2])^2)
    local bian14=math.sqrt((p1[1]-p4[1])^2+(p1[2]-p4[2])^2)
    local bian32=math.sqrt((p3[1]-p2[1])^2+(p3[2]-p2[2])^2)
    local bian34=math.sqrt((p3[1]-p4[1])^2+(p3[2]-p4[2])^2)
    local bian24=math.sqrt((p2[1]-p4[1])^2+(p2[2]-p4[2])^2)

    local p01=(bian12+bian14+bian24)/2
    local s1=math.sqrt(p01*(p01-bian12)*(p01-bian14)*(p01-bian24))         --海伦公式
    local p02=(bian32+bian34+bian24)/2
    local s2=math.sqrt(p02*(p02-bian32)*(p02-bian34)*(p02-bian24))
    local s=math.floor(s1+s2)                                               --四边形面积

    local bian1_=math.sqrt((p1[1]-point[1])^2+(p1[2]-point[2])^2)
    local bian2_=math.sqrt((p2[1]-point[1])^2+(p2[2]-point[2])^2)
    local bian3_=math.sqrt((p3[1]-point[1])^2+(p3[2]-point[2])^2)
    local bian4_=math.sqrt((p4[1]-point[1])^2+(p4[2]-point[2])^2)

    if bian12==bian1_+bian2_ or bian32==bian3_+bian2_ or bian34==bian3_+bian4_ or bian14==bian1_+bian4_ then  --点在边上
        return true
    end

    local pp1=(bian12+bian1_+bian2_)/2
    local pp2=(bian32+bian3_+bian2_)/2
    local pp3=(bian34+bian3_+bian4_)/2
    local pp4=(bian14+bian1_+bian4_)/2

    local ss1=math.sqrt(pp1*(pp1-bian12)*(pp1-bian1_)*(pp1-bian2_))
    local ss2=math.sqrt(pp2*(pp2-bian32)*(pp2-bian3_)*(pp2-bian2_))
    local ss3=math.sqrt(pp3*(pp3-bian34)*(pp3-bian3_)*(pp3-bian4_))
    local ss4=math.sqrt(pp4*(pp4-bian14)*(pp4-bian1_)*(pp4-bian4_))
    local ss=math.floor(ss1+ss2+ss3+ss4)
    if  ss==s then
        return true
    else
        return false
    end

end

return SceneZombie
