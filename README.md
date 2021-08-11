# Installation
*HPGuppiDaq relies on the Hashpipe and Hashpipe_jll packages, which contain bugs that do not allow you to simply `]add HPGuppiDaq`*

To install this package:
1. clone the repository
```
git clone https://github.com/dkhimey/HPGuppiDaq.git
```

2. activate the HPGuppiDaq Julia environment
```
julia --project=HPGuppiDaq
```

3. Install dependencies
```
]instantiate
```

It will now be possible to import HPGuppiDaq by `using HPGuppiDaq`.


# Contents
- ### [Modules](https://github.com/dkhimey/HPGuppiDaq#modules)
    + [HashpipeUtils](https://github.com/dkhimey/HPGuppiDaq#hashpipeutilsjl)
    + [StatusBuff](https://github.com/dkhimey/HPGuppiDaq#statusbuffjl)
    + [DataBuffFFT](https://github.com/dkhimey/HPGuppiDaq#databufffftjl)
    + [DataToRedis](https://github.com/dkhimey/HPGuppiDaq#datatoredisjl)
    + [DataFromRedis](https://github.com/dkhimey/HPGuppiDaq#datafromredisjl)
    + [DataBuffDisplay](https://github.com/dkhimey/HPGuppiDaq#databuffdisplayjl)
    + [RedisDisplay](https://github.com/dkhimey/HPGuppiDaq#redisdisplayjl)

- ### [Tutorial](https://github.com/dkhimey/HPGuppiDaq#tutorial-1)
    + [Attaching and loading data](https://github.com/dkhimey/HPGuppiDaq#attaching-to-a-data-buffer-and-loading-in-data)
    + [Display](https://github.com/dkhimey/HPGuppiDaq#option-1-simple-display)
    + [Redis Integration](https://github.com/dkhimey/HPGuppiDaq#option-2-redis)
    + [FFT](https://github.com/dkhimey/HPGuppiDaq#option-3-fft)
#
# **Modules**

*For more examples, please refer to the tests folder.*

- ### **HashpipeUtils.jl**

    Contains various code to perform computations such as calculating fft of data files, calculating power. Also contains a function to attach to a data buffer and create a vector of arrays that holds data from each data block.

    To begin tracking a data buffer from the REPL, run
    ```julia
    HashpipeUtils.track_databuffer((inst, nbuff, nblocks), 
                                    (np, nt, nc))
    ```
    where `inst` is the instance, `nbuff` is the number of the data buffer, `nblocks` is the total number of data blocks in the buffer (or the number you want read in, starting from the first block). The second input specifies the shape of the arrays stored in the data buffer where `np` is the number of polarizations, `nt` is the number of time steps, and `nc` is the number of coarse channels.

    To compute the FFT for a raw data file, run
    ```julia
    HashpipeUtils.hashpipe_fft(raw_data, nf, chan, np, nt, nc, integrated)
    ```
    `raw_data` must be of type `Array{Complex{Int8}, 3}` where `size(raw_data) == (np, nt, nc)`. `nf` is the number of fine channels per coarse channel (must be specified such that `nt` is an integer multiple of `nf`). `chan` is the coarse channel(s) for which to compute the FFT. `chan` can be specified as a range (ie `chan = 3:6`). `integrated` is a boolean value, automatically set to `true`. If set to `false`, will return an array of shape `(2, nf, nt÷nf, nchans)`, otherwise will sum spectra together along each coarse channel and return an array of shape `(np, nchans * nf)`.

    Other functions include `compute_pwr()`, which calculates the average power for each channel in a raw data array.

- ### **StatusBuff.jl**
    Will likely be merged into HashpipeUtils.jl at some point. This module contains functions that track the status buffer and access various fields within it.

    To retreive the value of a field in the Status Buffer, run
    ```julia
    st = Hashpipe.status_t(0,0,0,0)
    StatusBuff.getStatus(st, "FIELD", inst, Type)
    ```
    where `"FIELD"` is replaced with the label of a field in the status buffer and `Type` is the data type of the value stored at that field (ex: `Int`, `Float`, `String`).

    This module also contains a specific function for accessing the `"NULBLKIN"` field in the status buffer which can be run with
    ```julia
    StatusBuff.getnblkin(st)
    ```
- ### **DataBuffFFT.jl**
    This module contains a single function that continuously loops through the data blocks in a data buffer, stores the result of computing the FFT on each block in a circular array, and continuously displays the integrated spectra for the blocks stored in the circular array. To run:
    ```julia
    datablocks = HashpipeCalculations.track_databuffer((inst, nbuff, nblocks), (np, nt, nc))
    circarr = CircularArrayBuffer{Array{Float32, 2}}(n) #n is the number of blocks to be stored
    st = Hashpipe.status_t(0,0,0,0)
    DataBuffFFT.FFTread(datablocks, circarr, chan, st, inst = 0,
                        nf = 2^16, nblocks = 24,t = 1)
    ```
    *To further develop this module, it would be useful to add a functionality to the `FFTread()` function so various functions could be passed in to customize behavior.*

- ### **DataToRedis.jl**
    The function in this module can be used to push data (currently power data) to a Redis channel and send a publish message:
    ```julia
    datablocks = HashpipeCalculations.track_databuffer((inst, nbuff, nblocks), (np, nt, nc))
    DataToRedis.pushRedis(datablocks, t = 1) #t indicates the sleep time.
    ```
    *In the future, it would be useful to re-write this function in a way that makes it more customizable so different computed quantities can be pushed to Redis.*
- ### **DataFromRedis.jl**
    The main function in this module -- `readRedis()` -- accepts a function as an input, or automatically uses the `plotpwr()` function available in the module. The `readRedis()` function subscribes to publish messages and once such a message is received, runs the function passed to it.
- ### **DataBuffDisplay.jl**
    Provides several different plotting functions that produce a real-time display of the data passing from the data buffer. Currently, not fully updated/functional. 
    This module contains three different kinds of functions:
    + `snapshot_xxx()` - these produce a single snapshot of the data buffer at the time that the function is run
    + `display_xxx(t)` - these produce a new snapshot every `t` seconds, created using the higher order `display_snapshot()` function.
    + `gif_xxx(filename, n)` - these produce `n` snapshots and save them as a gif as the specified `filename`, created using the `gif_snapshot()` function.

    *These functions are poorly written and need some updating. Will likely be merged with the RedisDisplay.jl module.*
- ### **RedisDisplay.jl**
    Contains one function that plots power, used in the `DataFromRedis.jl `module.


# **Tutorial**
*For more examples, see tests folder.*

### **Attaching to a data buffer and loading in data**

For this example, we use the second data buffer on the first instance, which contains 24 blocks in each data buffer. Our data arrays have 2 polarizations, 524288 time samples, and 64 coarse channels.

```julia
inst, nbuff, nblocks = 0, 2, 24
np, nt, nc = 2, 524288, 64
# don't forget to set the hashpipe keyfile to point to the correct folder
# Ex: ENV["HASHPIPE_KEYFILE"]="/home/user"
```
To connect to the data buffer, we use a function in the HashpipeUtils module:
```julia
blks = HashpipeUtils.track_databuffer((inst, nbuff, nblocks), (np, nt, nc))
```
`blks` is a vector with `nblocks` (24, in our case) elements. Underneath the hood, this function uses the `unsafe_wrap()` function to access the data in each data block. What this means, is that the blks vector will automatically update and clear as data moves through the data buffer. Let's examine blk further:
```julia
julia> size(blks[1])
>> (2, 524288, 64)

julia> typeof(blks[1])
>> Array{Complex{Int8}, 3}
```
Each element in `blks` contains an array of size `(np, nt, nc)`, that holds complex integers (aka raw voltage data). 

### **Using the Data**
Now that we have the data loaded in, we can play around with it using some of the other functions in the modules.

1. #### **Option 1: Simple Display**

    One option is to create a simple display of the data running through the buffer. Display functions are available in `DataBuffDisplay.jl`.

    Using these functions it is possible to display a single snapshot of the data:
    ```julia
    <!-- TO-DO -->
    ```
    or a continuous diplay/saved gif:
    ```julia
    <!-- TO-DO -->
    ```
    Here is the gif produced:

    `<!-- TO-DO -->`

2. #### **Option 2: Redis**

    The second option, which is especially useful if mulitple compute nodes are running hashpipe, is to push the data to Redis. To do so, we can run:
    ```julia
    conn = RedisConnection(host="redishost")
    DataToRedis.pushRedis(conn, datablocks, channel = "data", key = "avgpwr", pubchan="chan-data", t = 1)
    # t is the amount of time that the script pauses between updates to Redis
    ```
    This function is now continously updating the `data` channel under the key `"avgpwr"` with the power of the raw data in `blks`. The host is automatically set to `redishost` but can be changed by adding the `host = ` argument in the function.
    Each time an update occurs, a message is sent to the `pubchan`.

    These Redis updating functions can be run on multiple nodes. To aggregate the data, a connection to Redis can be established from any node (preferably the head node).
    To do this, use the function:
    ```julia
    conn = RedisConnection(host="redishost")
    function func()
        # grab data from updated redis key
        abspwr = hget(conn, "data", "avgpwr")
        # convert abstract string to floats
        pwr = reinterpret(Float32, codeunits(abspwr))
        # reshape to original shape
        pwr = reshape(pwrarray, (2,1,64))
        # display plot using RedisDisplay module
        display(RedisDisplay.snapshot_power(avgpwr))
    end
    DataFromRedis.readRedis(conn, pubchan = "chan-data", func)
    ```
    This function listens to messges broadcast on the `pubchan` channel. Each time a message is received, the function runs `func()`. `func` is implemented by the user and can perform any number of calculations. An exmaple is given above and in `DataFromRedis.jl`. Ideally, this function will access the data on the channel and under the key previously set by the `pushRedis()` function, perform some calculations, and either plot or store the results.

3. #### **Option 3: FFT**

    A final option -- and one that is useful for signal searching -- is to perform Fast Fourier Transform calculations on the voltage data running through the hashpipe.

    These calculations occur in real time, so it would be highly inefficient to store all the FFT data for each block each time it updates (which is approximately every 5 seconds). However, we should store at least *some* data from blocks for a short period of time since a signal is typically only visible after integrating across several data blocks. Two things are necessary to achieve this: access to the Status Buffer (which contains informationa about which block is currently being written) and a circular array (created using the `CircularArrayBuffers` package).

    To do this:
    ```julia
    # attach to status buffer
    st = Hashpipe.status_t(0,0,0,0)
    # create circular array
    spectra = CircularArrayBuffer{Array{Float32, 2}}(5)
    ```

    To calculate the FFT, store the data in the `spectra` array, and plot the integrated spectra over 5 blocks run:
    ```julia
    DataBuffFFT.FFTread(blks, spectra, chan=7, st, inst = 0,
                 nf = 2^16, nblocks = 24,t = 1)
    ```

    This will produce a continously updating display of the signal (across 2^16 fine channels) in each polarization in the 7th coarse channel.

