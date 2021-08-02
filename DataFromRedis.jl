include("RedisDisplay.jl")
using .RedisDisplay, Redis

conn = RedisConnection(host="blh0")
# srt://blc00/0/spectra

function f(x)
    # grab data from redis
    abspwr = hget(conn, "srt://blc00/0/spectra", "avgpwr")
    # convert abstract sring to power array
    pwrarray = reinterpret(Float32, codeunits(abspwr))
    avgpwr = reshape(pwrarray, (2,1,64))

    # display
    display(RedisDisplay.snapshot_power(avgpwr))
end

# open redis subscribtion
sub = open_subscription(conn)

try
    # subsrcribe to channel where messages are being sent
    subscribe(sub, "chan-srt://blc00/0/spectra", f)
catch e
    # attempts are handling keyboard interruptions, doesnt work yet
    if isa(e, InterruptException)
        Redis.unsubscribe(sub, "chan-srt://blc00/0/spectra")
        println("Connection Closed.")
    end
end