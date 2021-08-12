module HashpipeApps
    using ..HashpipeUtils
    using Hashpipe
    using Redis
    using FFTW
    using Plots
    using Statistics

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

    # ********DISPLAYS********
    """
        display_snapshot(snapshot_func, data, t = 1)

    Produces a continuous display using the `snapshot_func` function, which should return a plot of the `data` input.
    `data` should directly access the data buffer blocks such that the values stored in the vector/array are changing as snapshot_func produces graphs.
    Takes a `t` second pause between calculations.
    """
    function display_snapshot(snapshot_func, data, t = 1)
        i = 0
        while true
            println(i)
            display(snapshot_func(data))
            i+=1
            sleep(t)
        end
    end

    """
        gif_snapshot(snapshot_func, data, filename, n=50)

    Produces a gif of a continuous display using the `snapshot_func` function, which should return a plot of the `data` input.
    `data` should directly access the data buffer blocks such that the values stored in the vector/array are changing as snapshot_func produces graphs.
    Combines `n` snapshots.
    """
    function gif_snapshot(snapshot_func, data, filename, n=50)
        anim = @animate for i ∈ 1:n
            snapshot_func(data)
        end
        gif(anim, filename)
    end

    """
        snapshot_power(datablocks)

    Displays average in the 1st and 2nd polarizations alongside histograms of the real components of the data.
    datablocks` is the output of the `HashpipeUtils.track_databuffer` function.

    Function has sub-optimal performance, it is recommended that the input be limited to a few blocks.
    """
    function snapshot_power(datablocks) # very slow when perfromed on multiple blocks, limit to a few -- needs improvement
        avg_pwr = HashpipeUtils.compute_pwr.(datablocks)
        integrated_pwr = sum(avg_pwr)

        l1 = @layout [a ; b]
        pol1 = integrated_pwr[1,1,:]
        pol2 = integrated_pwr[2,1,:]

        p1 = plot(pol1, title="Pol. 1, Total Power", ylims=(minimum(pol1)-std(pol1), maximum(pol1)))
        p2 = plot(pol2, title="Pol. 2, Total Power", ylims=(minimum(pol2)-std(pol2), maximum(pol2)))

        p = plot(p1, p2, layout = l1, legend = false, titlefontsize=10, 
                xlabel="Coarse Channel", ylabel="Average Power")


        reals = real.(datablocks)
        integrated_reals = sum(reals)
        l1 = @layout [a ; b]
        h1 = histogram(integrated_reals[1,:,1])
        h2 = histogram(integrated_reals[2,:,1])
        h = plot(h1, h2, layout = l1, legend = false, xlabel="Re(voltage)")

        l2 = @layout [a{0.7w} b]
        return plot(p, h, layout = l2)
    end

    """
        display_power(data, t = 1)

    Continuous display of average power and histograms for both polarizations. 
    Example usage of the snapshot_power and display_snapshot functions to produce a desired display.
    """
    display_power(data, t = 1) = display_snapshot(snapshot_power, data, t)
end