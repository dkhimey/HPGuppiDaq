include("HashpipeUtils.jl")
using .HashpipeUtils, Redis

# inst, nbuff = 0, 2
# np, nt, nc = 2, 512*1024, 64
# nblocks = 24
# blks = HashpipeUtils.track_databuffer((inst, nbuff, nblocks), (np, nt, nc))

# channel = "srt://blc00/0/spectra"
# key = "avgpwr"
# pubchan="chan-srt://blc00/0/spectra"
function pushRedis(redisconnection, datablocks, channel, key,
                   pubchan, t = 1)
    while true
        println("pushing.....")
        # compute power
        power = HashpipeUtils.compute_pwr.(datablocks) #this takes forever
        # convert power array to abstract string
        abspwr = unsafe_string(Ptr{UInt8}(pointer(power)), sizeof(power))
        # add abstract string to redis
        hset(conn, channel, key, abspwr)
        # publish ready message
        publish(redisconnection, pubchan, "data ready")
    
        # wait
        sleep(t)
    end
end
