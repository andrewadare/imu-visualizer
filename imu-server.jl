using HttpServer
using WebSockets
using LibSerialPort
import JSON


function send_imu_data(client::WebSockets.WebSocket)
    sp = open(ARGS[1], parse(Int, ARGS[2]))
    input_line = ""
    mcu_message = ""

    println("Starting I/O loop. Press ESC [return] to quit")

    while true
        # Poll for new data without blocking
        @async input_line = readline(STDIN, chomp=false)
        @async mcu_message *= readstring(sp)

        contains(input_line, "\e") && quit()

        # Send user input to device
        if endswith(input_line, '\n')
            write(sp, "$input_line")
            input_line = ""
        end

        if contains(mcu_message, "\r\n")
            lines = split(mcu_message, "\r\n")
            while length(lines) > 1
                line = shift!(lines)
                # println(line)  # debug
                try
                    data_dict = JSON.parse(line)
                    msg = Dict{AbstractString, Any}()
                    msg["type"] = "angles"
                    msg["data"] = data_dict
                    msg["timestamp"] = time()
                    write(client, JSON.json(msg))
                end
            end
            mcu_message = lines[1]
        end

        # Give the queued tasks a chance to run
        sleep(0.0001)
    end
    return nothing
end


"""
Serve page(s) and supporting files over HTTP. Assumes the server is started
from the location of this script. Searches through server root directory and
subdirectories recursively for the requested resource.
"""
function http_handler()
    httph = HttpHandler() do req::Request, res::Response
        # Handle case where / means index.html
        if req.resource == "/"
            println("serving ", req.resource)
            return Response(readstring("index.html"))
        end
        # Serve requested file if found, else return a 404.
        for (root, dirs, files) in walkdir(".")
            for file in files
                file = replace(joinpath(root, file), "./", "")
                if startswith("/$file", req.resource)
                    println("serving ", file)
                    return Response(open(readstring, file))
                end
            end
        end
        return Response(404)
    end
    httph.events["error"] = (client, err) -> println(err)
    httph.events["listen"] = (port) -> println("Listening on $port...")
    return httph
end


function websocket_handler(callback::Function, callback_args::AbstractVector=[])
    wsh = WebSocketHandler() do req, client
        println("Handling WebSocket client")
        println("    client.id: ",         client.id)
        println("    client.socket: ",     client.socket)
        println("    client.is_closed: ",  client.is_closed)
        println("    client.sent_close: ", client.sent_close)

        while true
            # Read string from client, decode, and parse to Dict
            msg = JSON.parse(String(copy(read(client))))
            if haskey(msg, "text") && msg["text"] == "ready"
                println("Received update from client: ready")
                callback(client, callback_args...)
            end
        end
    end
    return wsh
end


function main()
    if length(ARGS) != 2
        println("Usage: $(basename(@__FILE__)) port baudrate.")
        println("Available ports:")
        list_ports()
        return
    end

    httph = http_handler()
    wsh = websocket_handler(send_imu_data)

    # Instantiate and start a websockets/http server
    server = Server(httph, wsh)

    println("Starting WebSocket server.")
    run(server, 8000)
end

main()