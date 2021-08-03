module DataBuffFFT
include("HashpipeUtils.jl")
include("StatusBuff.jl")
using .HashpipeUtils, .StatusBuff, Hashpipe, FFTW, CircularArrayBuffers, Plots

# loop: read status buffer, FFT of nblkin-1, add to circular array, display
function FFTread(datablocks, circarr, chan, st, inst = 0, nf = 2^16, t = 1)
    while true
        blk = StatusBuff.getnblkin(st, inst)
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

end