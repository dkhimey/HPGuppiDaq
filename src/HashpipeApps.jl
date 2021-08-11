module HashpipeApps
    include("HashpipeUtils.jl")

    using .HashpipeUtils
    using Hashpipe
    using Redis
    using FFTW
    using Plots
    # ********DISPLAYS********

    # ********REDIS INTEGRATION********
    """
    """
    function pushRedis(redisconnection, datablocks, channel, key,
        pubchan, t = 1)
        while true
            println("pushing.....")
            # compute power
            power = HashpipeUtils.compute_pwr.(datablocks) #this takes forever
            # convert power array to abstract string
            abspwr = unsafe_string(Ptr{UInt8}(pointer(power)), sizeof(power))
            # add abstract string to redis
            hset(conn, channel, key, abspwr)
            # publish ready message
            publish(redisconnection, pubchan, "data ready")

            # wait
            sleep(t)
        end
    end

    """
    """
    function readRedis(redisconnection, pubchan, func)
        # open redis subscribtion
        sub = open_subscription(redisconnection)
        # listen for messages on pubchan and perform func
        subscribe(sub, pubchan, func)
    end

    # ********REAL TIME FFT********
    """
    """
    function FFTread(datablocks, n, chan, func, st, inst = 0,
                     nf = 2^16, nblocks = 24,t = 1)
        shape = (size(datablocks[1],1), nf)
        totalpower = zeros(shape)
        circarr = HashpipeUtils.init_circarray(n, shape)
        while true
            blk = HashpipeUtils.getnblkin(st, inst)
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

            # subtract oldest spectrum
            totalpower -= circarr[1]
            # add newest spectrum
            totalpower += pwr
            # store new spectrum in circarr
            push!(circarr, pwr)

            func(totalpower)
            sleep(t) #wait
        end
    end
end