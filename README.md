# Usage

*For more examples, please refer to the tests folder.*

- ## **HashpipeUtils.jl**

    Contains various code to perform computations such as calculating fft of data files, calculating power. Also contains a function to attach to a data buffer and create a vector of arrays that holds data from each data block.

    To begin tracking a data buffer run
    ```julia
    HashpipeUtils.track_databuffer((inst, nbuff, nblocks), 
                                    (np, nt, nc))
    ```
    where `inst` is the instance, `nbuff` is the number of the data buffer, `nblocks` is the total number of data blocks in the buffer (or the number you want read in, starting from the 0th block). The second input specifies the shape of the arrays stored in the data buffer where `np` is the number of polarizations, `nt` is the number of time steps, and `nc` is the number of coarse channels.

    To compute the FFT for a raw data file, run
    ```julia
    HashpipeUtils.hashpipe_fft(raw_data, nf, chan, np, nt, nc, integrated)
    ```
    `raw_data` must be of type `Array{Complex{Int8}, 3}` where `size(raw_data) == (np, nt, nc)`. `nf` is the number of fine channels per coarse channel (must be specified such that `nt` is an integer multiple of `nf`). `chan` is the coarse channel(s) for which to compute the FFT. `chan` can be specified as a range (ie `chan = 3:6`). `integrated` is a boolean value, automatically set to `true`. If set to `false`, will return an array of shape `(2, nf, nt÷nf, nchans)`, otherwise will sum spectra together along each coarse channel and return an array of shape `(np, nchans * nf)`.

    Other functions include `compute_pwr()`, which calculates the average power for each channel in a raw data array.

- ## **StatusBuff.jl**
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
- ## **DataBuffFFT.jl**
    This module contains a single function that continuously loops through the data blocks in a data buffer, stores the result of computing the FFT on each block in a circular array, and continuously displays the integrated spectra for the blocks stored in the circular array. To run:
    ```julia
    datablocks = HashpipeCalculations.track_databuffer((inst, nbuff, nblocks), (np, nt, nc))
    circarr = CircularArrayBuffer{Array{Float32, 2}}(n) #n is the number of blocks to be stored
    st = Hashpipe.status_t(0,0,0,0)
    DataBuffFFT.FFTread(datablocks, circarr, chan, st, inst = 0,
                        nf = 2^16, nblocks = 24,t = 1)
    ```
    *To further develop this module, it would be useful to add a functionality to the `FFTread()` function so various functions could be passed in to customize behavior.*

- ## **DataToRedis.jl**
    The function in this module can be used to push data (currently power data) to a Redis channel and send a publish message:
    ```julia
    datablocks = HashpipeCalculations.track_databuffer((inst, nbuff, nblocks), (np, nt, nc))
    DataToRedis.pushRedis(datablocks, t = 1) #t indicates the sleep time.
    ```
    *In the future, it would be useful to re-write this function in a way that makes it more customizable so different computed quantities can be pushed to Redis.*
- ## **DataFromRedis.jl**
    The main function in this module -- `readRedis()` -- accepts a function as an input, or automatically uses the `plotpwr()` function available in the module. The `readRedis()` function subscribes to publish messages and once such a message is received, runs the function passed to it.
- ## **DataBuffDisplay.jl**
    Provides several different plotting functions that produce a real-time display of the data passing from the data buffer. Currently, not fully updated/functional. 
    This module contains three different kinds of functions:
    + `snapshot_xxx()` - these produce a single snapshot of the data buffer at the time that the function is run
    + `display_xxx(t)` - these produce a new snapshot every `t` seconds, created using the higher order `display_snapshot()` function.
    + `gif_xxx(filename, n)` - these produce `n` snapshots and save them as a gif as the specified `filename`, created using the `gif_snapshot()` function.

    *These functions are poorly written and need some updating. Will likely be merged with the RedisDisplay.jl module.*
- ## **RedisDisplay.jl**
    Contains one function that plots power, used in the `DataFromRedis.jl `module.