using HashpipeCalculations, Redis
ENV["HASHPIPE_KEYFILE"]="/home/davidm"

inst, nbuff, nblock = 0, 2, 0

# ----- INPUT
# nc, np, nt = 64, 2, 512*1024
try nc, np, nt = Int(ARGS[1]), Int(ARGS[2]), Int(ARGS[3])
catch e
    nc = hget(conn, "srt://blc00/0/status", "OBSSCHAN")
    np = 2
    nt = none
end

data = track_databuffer((inst, nbuff, nblock), (nc, np, nt))
conn = RedisConnection(host="blh0")

avgpwr = compute_pwr(data, nt)
abspwr = unsafe_string(Ptr{UInt8}(pointer(avgpwr)), sizeof(avgpwr))
hset(conn, "srt://blc00/0/spectra", "avgpwr", abspwr)

# fft = hashpipe_fft(data, np, nt, nc)
# absfft = unsafe_string(Ptr{UInt8}(pointer(fft)), sizeof(fft))
# hset(conn, "srt://blc00/0/spectra", "fft", absfft)




