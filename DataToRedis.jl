include("HashpipeCalculations.jl")
using .HashpipeCalculations, Redis

inst, nbuff = 0, 2
np, nt, nc = 2, 512*1024, 64
nblock = 0

# track databuffer
data = HashpipeCalculations.track_databuffer((inst, nbuff, nblock), (np, nt, nc))
# connect to redis
conn = RedisConnection(host="redishost")

while true
    # compute power
    power = HashpipeCalculations.compute_pwr(data, nt)
    # convert power array to abstract string
    abspwr = unsafe_string(Ptr{UInt8}(pointer(power)), sizeof(power))
    # add abstract string to redis
    hset(conn, "srt://blc00/0/spectra", "avgpwr", abspwr)
    # publish ready message
    publish(conn, "chan-srt://blc00/0/spectra", "data ready")

    # wait
    sleep(2)
end