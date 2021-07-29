include("calculations.jl")
using .HashpipeCalculations, Hashpipe, FFTW

# track databuffer
inst, nbuff = 0, 2
np, nt, nc = 2, 512*1024, 64
ENV["HASHPIPE_KEYFILE"]="/home/davidm"
# attach to data buffer
pdb = Hashpipe.databuf_attach(inst, nbuff)

blockdata = []

nblock = 0
while nblock < 3
    println(nblock)
    pb = Hashpipe.databuf_data(pdb, nblock)
    pz = Ptr{Complex{Int8}}(pb+2560*80)
    push!(blockdata, unsafe_wrap(Array, pz, (np, nt, nc)))
    nblock+=1
end

# chan = 7
# n = 2^16
# pwr = HashpipeCalculations.hashpipe_fft(data, n, chan)