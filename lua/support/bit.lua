bit = {}

function bit.lshift(num, bnum)  --左移
    local ret = math.floor(num) * (2^bnum)
    return ret
end

function bit.bor(num1, num2)    --或
    num1 = math.floor(num1)
    num2 = math.floor(num2)
    local ret = 0
    local tmp1, tmp2
    local rate = 1
    while num1>0 and num2>0 do
        tmp1 = num1%2
        tmp2 = num2%2
        if tmp1>0 or tmp2>0 then
            ret = ret+rate
        end
        num1 = (num1-tmp1)/2
        num2 = (num2-tmp2)/2
        rate = rate*2
    end
    ret = ret+(num1+num2)*rate
    return ret
end

function bit.band(num1, num2)   --与
    num1 = math.floor(num1)
    num2 = math.floor(num2)
    local ret = 0
    local tmp1, tmp2
    local rate = 1
    while num1>0 and num2>0 do
        tmp1 = num1%2
        tmp2 = num2%2
        if tmp1>0 and tmp2>0 then
            ret = ret+rate
        end
        num1 = (num1-tmp1)/2
        num2 = (num2-tmp2)/2
        rate = rate*2
    end
    return ret
end
