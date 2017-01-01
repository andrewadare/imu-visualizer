using HttpServer
using WebSockets
using LibSerialPort
import JSON

"""
Write JSON-formatted message to websocket client.
Recipients expect the schema defined here, so modify with care.
"""
function send_json(name::AbstractString, data::Any, client::WebSockets.WebSocket)
    msg = Dict{AbstractString, Any}()
    msg["type"] = name
    msg["data"] = data
    msg["timestamp"] = time()
    write(client, JSON.json(msg))
end

"""
Find files recursively in `dir` containing `substr`, e.g.
    find("js", ".js")
Returns result as an array of strings.
"""
function find(dir::AbstractString, substr::AbstractString)
    local out = Vector{String}()

    function findall(dir, substr)
        f = readdir(abspath(dir))
        for i in f
            path = joinpath(dir, i)
            if isfile(path) && contains(path, substr)
                push!(out, path)
            end
            if isdir(path)
                findall(path, substr)
            end
        end
    end

    findall(dir, substr)

    out
end

"""
From a csv line like this:

Time:67549,H:254.37,R:-1.44,P:3.81,A:3,M:3,G:3,S:3

create and return a Dict object. If the line can't be split into at least n
items, an empty Dict is returned.
"""
function line2dict(line::AbstractString, n::Integer)
    d = Dict{String, Float64}()
    a = split(line, ",")
    length(a) == n || return d
    for item in a
        contains(item, ":") || return d
        k,v = split(item, ":")
        f = parse(Float64, v)
        d[k] = f
    end
    d
end

"""
From a csv line like this:

Time:67549,H:254.37,R:-1.44,P:3.81,A:3,M:3,G:3,S:3

create and return a Dict object. The keys array contains the items to be
included in the Dict. If the line can't be split into at least length(keys),
an empty Dict is returned.
"""
function line2dict(line::AbstractString, keys::Array{AbstractString})
    d = Dict{String, Float64}()
    a = split(line, ",")
    length(a) >= length(keys) || return d
    for item in a
        contains(item, ":") || return d
        k,v = split(item, ":")
        if in(k, keys)
            f = parse(Float64, v)
            d[k] = f
        end
    end
    d
end

function validate_args()

    if length(ARGS) != 2
        println("Usage:")
        println("julia imu-server.jl address speed")
        println("\nAvailable ports:\n")
        list_ports()
        exit()
    end

    port_address = ARGS[1]
    if !ischardev(port_address)
        error("\n\n$port_address is not a valid character device.\n\n")
    end

    bps = ARGS[2]
    if !isnumber(bps)
        error("\n\n$bps is not a valid connection speed.\n\n")
    end
end

function send_imu_data(client::WebSockets.WebSocket)
    port_address = ARGS[1]
    sp = SerialPort(port_address)
    open(sp)
    set_speed(sp, parse(Int, ARGS[2]))
    set_frame(sp, ndatabits=8, parity=SP_PARITY_NONE, nstopbits=1)

    keys = ["Time" ,"qw", "qx", "qy", "qz", "A", "M", "G", "S"]
    nkeys = length(keys)

    while true
        line = readline(sp)
        d = line2dict(line, nkeys)
        send_json("angles", d, client)
    end

end

wsh = WebSocketHandler() do req, client
    println("Handling WebSocket client")
    println("    client.id: ",         client.id)
    println("    client.socket: ",     client.socket)
    println("    client.is_closed: ",  client.is_closed)
    println("    client.sent_close: ", client.sent_close)

    while true

        # Read string from client, decode, and parse to Dict
        msg = JSON.parse(bytestring(read(client)))

        if haskey(msg, "text") && msg["text"] == "ready"
            println("Received update from client: ready")

            send_imu_data(client)
        end
    end
end

"""
Serve page(s) and supporting files over HTTP.
"""
httph = HttpHandler() do req::Request, res::Response

    files = ["index.html"; find("js", ".js")]

    for file in files
        if startswith("/$file", req.resource)
            println("serving /", file)
            return Response(open(readstring, file))
        end
    end

    Response(404)
end

httph.events["error"]  = (client, err) -> println(err)
httph.events["listen"] = (port)        -> println("Listening on $port...")

validate_args()

# Instantiate and start a websockets/http server
server = Server(httph, wsh)

println("Starting WebSocket server.")
run(server, 8000)
