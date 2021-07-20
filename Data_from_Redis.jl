using .Display, Redis

conn = RedisConnection(host="blh0")
# srt://blc00/0/spectra
abspwr = hget(conn, "srt://blc00/0/spectra", "avgpwr")
absfft = hget(conn, "srt://blc00/0/spectra", "fft")

pwrarray = reinterpret(Float64, codeunits(abspwr))
fftarray = reinterpret(Float64, codeunits(absfft))

avgpwr = reshape(pwrarray, (2,1,64))
fft = reshape(fftarray, (2, 8192))



