include("HashpipeUtils.jl")
using .HashpipeUtils, Redis

# inst, nbuff = 0, 2
# np, nt, nc = 2, 512*1024, 64
# nblocks = 24
# blks = HashpipeUtils.track_databuffer((inst, nbuff, nblocks), (np, nt, nc))

function pushRedis(datablocks, t = 1)
    # connect to redis
    conn = RedisConnection(host="redishost")
    while true
        println("pushing.....")
        # compute power
        power = HashpipeUtils.compute_pwr.(datablocks) #this takes forever
        # convert power array to abstract string
        abspwr = unsafe_string(Ptr{UInt8}(pointer(power)), sizeof(power))
        # add abstract string to redis
        hset(conn, "srt://blc00/0/spectra", "avgpwr", abspwr)
        # publish ready message
        publish(conn, "chan-srt://blc00/0/spectra", "data ready")
    
        # wait
        sleep(t)
    end
end
