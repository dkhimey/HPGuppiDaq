include("HashpipeCalculations.jl")
include("StatusBuff.jl")
using .HashpipeCalculations, .StatusBuff, Hashpipe, FFTW, CircularArrayBuffers, Plots

# attach to data buffer & get data in blocks
datablocks = HashpipeCalculations.track_databuffer((0, 2, 24), (2, 512*1024, 64))

# attach to status buffer
st = Hashpipe.status_t(0,0,0,0)
Hashpipe.status_attach(0, Ref(st))

# create circular array to store spectra
# https://juliahub.com/ui/Packages/CircularArrayBuffers/HOj1r/0.1.2
spectra = CircularArrayBuffer{Array{Float32, 2}}(5)

# loop: read status buffer, FFT of nblkin-1, add to circular array, display
function read(circarr = spectra , nf = 2^16, chan = 7, t = .1)
    while true
        blk = StatusBuff.getnblkin(st)
        # *****improve this******
        if blk== 0
            blk = 24
        end
        # ***********************

        # the nth block of the data buffer is at the n+1th index in datablocks
        # therefore, datablocks[n] is accessing the block before the one currently written
        pwr = HashpipeCalculations.hashpipe_fft(datablocks[blk], nf, chan) #compute fft
        HashpipeCalculations.remove_DCspike(pwr) #remove DC spike
        push!(circarr, pwr) #add to circular array
        display(plot(sum(circarr)[1, :], title = string(blk))) #display integrated circular array
        sleep(t) #wait
    end
end
