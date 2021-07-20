using HashpipeCalculations, Redis
ENV["HASHPIPE_KEYFILE"]="/home/davidm"
# ----- INPUT
inst, nbuff, nblock = 0, 2, 0
# OBSNCHAN, 2 (or NPOL?), ???
nc, np, nt = 64, 2, 512*1024
# try ARGS[1], ARGS[2], ARGS[3]
# catch e
#     # read status buffer
# end

# ----- DATA
# attach to data buffer
data = track_databuffer()

# calculations
avgpwr = compute_pwr(data, nt)
fft = hashpipe_fft(data, np, nt, nc)

# ----- data to abstract string
abspwr = unsafe_string(Ptr{UInt8}(pointer(avgpwr)), sizeof(avgpwr))
absfft = unsafe_string(Ptr{UInt8}(pointer(fft)), sizeof(fft))

# ------ Redis
conn = RedisConnection(host="blh0")
# srt://blc00/0/spectra
hset(conn, "srt://blc00/0/spectra", "avgpwr", absstr)
hset(conn, "srt://blc00/0/spectra", "fft", absfft)




