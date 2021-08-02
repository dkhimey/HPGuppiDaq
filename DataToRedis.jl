include("HashpipeCalculations.jl")
include("params.jl")
using .HashpipeCalculations, Redis
ENV["HASHPIPE_KEYFILE"]="/home/davidm"

inst, nbuff = params.inst, params.nbuff
np, nt, nc = params.np, params.nt, params.nc
nblock = 0

# track databuffer
data = HashpipeCalculations.track_databuffer((inst, nbuff, nblock), (np, nt, nc))
# connect to redis
conn = RedisConnection(host="blh0")


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