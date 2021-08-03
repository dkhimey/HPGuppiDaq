include("HashpipeUtils.jl")
include("StatusBuff.jl")
using .HashpipeUtils, .StatusBuff, Hashpipe, FFTW, CircularArrayBuffers, Plots

# attach to data buffer & get data in blocks
blks = HashpipeUtils.track_databuffer((0, 2, 24), (2, 512*1024, 64))

# attach to status buffer
stsv = StatusBuff.track_statusbuff(0)

# create circular array to store spectra
# https://juliahub.com/ui/Packages/CircularArrayBuffers/HOj1r/0.1.2
spectra = CircularArrayBuffer{Array{Float32, 2}}(5)

# loop: read status buffer, FFT of nblkin-1, add to circular array, display
function FFTread(datablocks, circarr = spectra , nf = 2^16, chan = 7, t = .1)
    while true
        blk = StatusBuff.getnblkin(stsv)
        # *****improve this******
        if blk== 0
            blk = 24
        end
        # ***********************

        # the nth block of the data buffer is at the n+1th index in datablocks
        # therefore, datablocks[n] is accessing the block before the one currently written
        pwr = HashpipeUtils.hashpipe_fft(datablocks[blk], nf, chan) #compute fft
        HashpipeUtils.remove_DCspike(pwr) #remove DC spike
        push!(circarr, pwr) #add to circular array
        display(plot(sum(circarr)[1, :], title = string(blk))) #display integrated circular array
        sleep(t) #wait
    end
end
