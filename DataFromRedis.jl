include("RedisDisplay.jl")
using .RedisDisplay, Redis

conn = RedisConnection(host="blh0")
# srt://blc00/0/spectra

function f(x)
    println(x)
    abspwr = hget(conn, "srt://blc00/0/spectra", "avgpwr")
    pwrarray = reinterpret(Float32, codeunits(abspwr))
    avgpwr = reshape(pwrarray, (2,1,64))

    # display
    display(RedisDisplay.snapshot_power(avgpwr))
end

function exit(x)
    
    println("Connection Closed")
end

sub = open_subscription(conn)

try
    subscribe(sub, "chan-srt://blc00/0/spectra", f)
catch e
    if isa(e, InterruptException)
        Redis.unsubscribe(sub, "chan-srt://blc00/0/spectra")
        println("Connection Closed.")
    end
end