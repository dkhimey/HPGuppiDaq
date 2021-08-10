module DataBuffFFT
    include("HashpipeUtils.jl")
    include("StatusBuff.jl")
    using Hashpipe, FFTW, CircularArrayBuffers, Plots, ..HashpipeUtils

    # loop: read status buffer, FFT of nblkin-1, update total power, perform function on total power
    function FFTread(datablocks, n, chan, func, st, inst = 0,
        nf = 2^16, nblocks = 24,t = 1)
        totalpower = zeros((size(datablocks[1],1), nf))
        circarr = HashpipeUtils.init_circarray(n)
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
            HashpipeUtils.remove_DCspike(pwr) #remove DC spike

            # subtract oldest power
            totalpower -= circarr[1]
            # add newest power
            totalpower += pwr
            # store new spectrum in circarr
            push!(circarr, pwr)

            func(totalpwr)
            # display(plot(sum(circarr)[1, :], title = string(blk))) #display integrated circular array
            sleep(t) #wait
        end
    end
end

