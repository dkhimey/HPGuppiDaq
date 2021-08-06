include("RedisDisplay.jl")
using .RedisDisplay, Redis

function processdata()
    # grab data from redis
    abspwr = hget(conn, "srt://blc00/0/spectra", "avgpwr")
    # convert abstract sring to power array
    pwrarray = reinterpret(Float32, codeunits(abspwr))
    avgpwr = reshape(pwrarray, (2,1,64))
    return avgpwr
end

function plotpwr()
    avgpwr = processdata()
    # display
    display(RedisDisplay.snapshot_power(avgpwr))
end

function readRedis(func = plotpwr, pubchan = "chan-srt://blc00/0/spectra", host = "redishost")
    conn = RedisConnection(host=host)
    # open redis subscribtion
    sub = open_subscription(conn)
    subscribe(sub, pubchan, func)