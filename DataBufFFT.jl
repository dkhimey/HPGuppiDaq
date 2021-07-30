include("HashpipeCalculations.jl")
include("StatusBuff.jl")
using .HashpipeCalculations, .StatusBuff, Hashpipe, FFTW, CircularArrayBuffers, Plots

# databuffer properties
inst, nbuff = 0, 2
np, nt, nc = 2, 512*1024, 64
nblocks = 24

ENV["HASHPIPE_KEYFILE"]="/home/davidm"
# attach to data buffer
pdb = Hashpipe.databuf_attach(inst, nbuff)
# attach to status buffer
st = Hashpipe.status_t(0,0,0,0)
Hashpipe.status_attach(0, Ref(st))
nblkin=String(fill(0x0, 80))

datablocks = []
nblock = 0
while nblock < nblocks
    # println(nblock)
    pb = Hashpipe.databuf_data(pdb, nblock)
    pz = Ptr{Complex{Int8}}(pb+2560*80)
    push!(datablocks, unsafe_wrap(Array, pz, (np, nt, nc)))
    nblock+=1
end

# create circular array to store spectra
# https://juliahub.com/ui/Packages/CircularArrayBuffers/HOj1r/0.1.2
spectra = CircularArrayBuffer{Array{Float32, 2}}(5)

# loop: read status buffer, calculate power of nblkin-1, add to circular array, display
function read(n = 100, t = .1)
    i = 0
    while i < n
        blk = StatusBuff.getnblkin(st, nblkin)
        # println(blk) 
        if blk== 0
            blk = 24
        end
        # the nth block of the data buffer is at the n+1th index in datablocks
        # therefore, datablocks[n] is accessing the block before the one currently written
        pwr = HashpipeCalculations.hashpipe_fft(datablocks[blk], 2^16, 7)
        HashpipeCalculations.remove_DCspike(pwr)
        push!(spectra, pwr)
        display(plot(sum(spectra)[1, :], title = string(blk)))

        i+=1
        sleep(t)
    end
end
