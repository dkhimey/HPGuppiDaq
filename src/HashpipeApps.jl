module HashpipeApps
    include("HashpipeUtils.jl")

    using .HashpipeUtils
    using Hashpipe
    using Redis
    using FFTW
    using Plots
    using Statistics
    # ********DISPLAYS********

    # ********REDIS INTEGRATION********
    """
    pushRedis(redisconnection, datablocks, channel, key,
                       pubchan, t = 1)
    
    Connects to Redis via the specified `redisconnection`, stores `data` under the specified Redis `channel` and `key`, 
    publishes a message to `pubchan` that data has been updated, and waits for `t` seconds.
    """
    function pushRedis(redisconnection, data, channel, key,
                       pubchan, t = 1)
        while true
            println("pushing.....")
            # compute power
            # power = HashpipeUtils.compute_pwr.(datablocks) #this takes forever
            # convert power array to abstract string
            absdata = unsafe_string(Ptr{UInt8}(pointer(data)), sizeof(data))
            # add abstract string to redis
            hset(conn, channel, key, absdata)
            # publish ready message
            publish(redisconnection, pubchan, "data ready")

            # wait
            sleep(t)
        end
    end

    """
        readRedis(redisconnection, pubchan, func)

    Connects to Redis via the specified `redisconnection` (typically from the head node), subcribes to messages sent
    on `pubchan`. Each time a message is received, executes the function specified by `func`.
    """
    function readRedis(redisconnection, pubchan, func)
        # open redis subscribtion
        sub = open_subscription(redisconnection)
        # listen for messages on pubchan and perform func
        subscribe(sub, pubchan, func)
    end

    # ********REAL TIME FFT********
    """
        FFTread(datablocks, n, chan, func, st, inst = 0,
                nf = 2^16, nblocks = 24,t = 1)
    
    Performs Fast Fourier Transforms as data runs through the data buffer.
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