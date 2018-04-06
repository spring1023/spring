local hosts = {"192.168.5.76","139.196.194.74"}
local _host = hosts[2]
local _port = 51234
local G_SOCKET = nil

local Socket = {}

function Socket.getSocket()
    return G_SOCKET
end

function Socket.start()
    if G_SOCKET then
        G_SOCKET:close()
    end

    G_SOCKET = assert(socket.connect(_host,_port))
    print("G_SOCKET connect :",G_SOCKET:getpeername())
    print("G_SOCKET connect :",G_SOCKET:getsockname())
    --print("G_SOCKET connect :",G_SOCKET:getstats())

    G_SOCKET:settimeout(0)
end

function Socket.send(msg)
    if msg then
        --print("Socket.send",msg)
        G_SOCKET:send(msg)
    end
end

function Socket.receive()
    if not G_SOCKET then return nil end
    local response, receive_status=G_SOCKET:receive()
    if receive_status ~= "closed" then
        if response then
            if not string.find(response,"socketjump") then
                print("Receive Message:"..response)
            end
            return json.decode(response)
        end
    else
        print("Service Closed!")
    end
    return nil
end

function Socket.close()
    if G_SOCKET then
        G_SOCKET:close()
        G_SOCKET = nil
    end
end

_G["Socket"] = Socket
return Socket
