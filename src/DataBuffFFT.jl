module DataBuffFFT
    include("HashpipeUtils.jl")
    include("StatusBuff.jl")
    using Hashpipe, FFTW, CircularArrayBuffers, Plots

    # loop: read status buffer, FFT of nblkin-1, add to circular array, display
    function FFTread(datablocks, circarr, chan, st, inst = 0,
                    nf = 2^16, nblocks = 24,t = 1)
        totalpower = zeros(size(datablocks[1]))
        while true
            blk = StatusBuff.getnblkin(st, inst)
            # *****improve this******
            if blk== 0
                blk = nblocks
            end
            # ***********************

            # the nth block of the data buffer is at the n+1th index in datablocks
            # therefore, datablocks[n] is accessing the block before the one currently written
            fft = HashpipeUtils.hashpipe_fft(datablocks[blk], nf, chan) 
            pwr = HashpipeUtils.compute_pwr(fft, false, 3)[:,:, 1] #compute fft, pwr
            # pwr = reshape(pwr, (size(fft)[1], nf))
            HashpipeUtils.remove_DCspike(pwr) #remove DC spike
            # store new spectrum in circarr
            push!(circarr, pwr)

            # update the total
            # total = HashpipeUtils.integrate(circ)

            # display(plot(sum(circarr)[1, :], title = string(blk))) #display integrated circular array
            sleep(t) #wait
        end
    end
end