include("calculations.jl")
using .HashpipeCalculations, FFTW

# track databuffer
inst, nbuff = 0, 2
np, nt, nc = 2, 512*1024, 64

data = Array{pointer(Complex{Int8})}(undef,128, np, nt, nc)

nblock = 0
while nblock < 25
    println(nblock)
    # not a pointer :/ -- need a fix
    data[nblock+1, :, :, :] = HashpipeCalculations.track_databuffer((inst, nbuff, nblock), (np, nt, nc))
    nblock+=1
end


q = Queue{}()

chan = 7
n = 2^16
pwr = HashpipeCalculations.hashpipe_fft(data, n, chan)
dequeue!(q)
enqueue!(q, pwr)