module HashpipeUtils
    using Hashpipe, FFTW, CircularArrayBuffers

    """
        track_databuffer((inst, nbuff, nblocks), 
                                   (np, nt, nc))

    Connects to and tracks all data blocks in the data buffer.

    inst, nbuff, nblocks: specify the instance and number of the data buffer and the number of data blocks it contains
    
    np, nt, nc: the shape of the data stored in the data blocks (polarizations, time samples, coarse channels)
    """
    function track_databuffer((inst, nbuff, nblocks), 
                              (np, nt, nc))
        # attach to data buffer
        pdb = Hashpipe.databuf_attach(inst, nbuff)
        # initialize vector that will hold all datablocks
        datablocks = []
        nblock = 0
        while nblock < nblocks
            # pointer to data block
            pb = Hashpipe.databuf_data(pdb, nblock)
            # cast data to complex integers; offset by 2560*80 for header
            pz = Ptr{Complex{Int8}}(pb+2560*80)
            # add to vector
            push!(datablocks, unsafe_wrap(Array, pz, (np, nt, nc)))
            nblock+=1
        end
        return datablocks
    end

    """
        detect(raw_data)

    Computes the square of the absolute value of the complex voltage data in raw_data
    """
    function detect(raw_data)
        return abs2.(convert(Array{Complex{Float32}}, raw_data))
    end

    """
        integrate(arr, dim = 2)

    Integrates an array along a given dimension, automatically set to 2 if unspecified.
    """
    function integrate(arr, dim = 2)
        return sum(arr, dims = dim) #reshape?
    end

    """
        compute_pwr(raw_data, avg=true, dim=2)

    Computes power by calculating the magnitudes of the voltages stored in raw_data and integrates across the time dimension (set to 2).
    Power is averaged when avg=true.
    """
    function compute_pwr(raw_data, avg=true, dim=2)
        pwr = integrate(detect(raw_data), dim)
        if avg
            nt = size(raw_data)[dim]
            return pwr/nt
        else 
            return pwr
        end
    end

    """
        hashpipe_fft(raw_data, nf, chan)

    Computes the Fast Fourier Transform for raw voltage data with nf channelizations across coarse channel specified by chan. 

    chan can be specified as a single channel or a range (Ex: chan = 7, chan = 5:7, chan = :). Assumes that raw_data is shaped (np, nt, nc).
    """
    function hashpipe_fft(raw_data::Array{Complex{Int8}, 3}, nf, chan)
        np, nt, nc = size(raw_data)
        reshaped = @view reshape(raw_data, (np, nf, nt÷nf, nc))[:, :, :, chan]
        transformed = fft(reshaped, 2)
        return fftshift(transformed, 2) #(np, nf, nt/nf, nchans)
    end

    """
        remove_DCspike(pwr_array)

    Removes the DC spike at the center of the second dimension of pwr_array which should be shaped as (number of polarizations, number of fine channels).
    """
    function remove_DCspike(pwr_array)
        n = size(pwr_array)[2]
        pwr_array[:,n÷2 + 1] = ((@view pwr_array[:,n÷2]) + (@view pwr_array[:,n÷2 + 2]))/2
    end

    """
        init_circarray(n, shape)

    Initializes a circular array with zeros, used for FFTread function to compute a rolling total power.
    """
    function init_circarray(n, shape)
        circ = CircularArrayBuffer{Array{Float32, 2}}(n)
        i = 0
        while i < n
            push!(circ, zeros(shape))
            i += 1
        end
        return circ
    end

    # ********STATUS BUFFER*********
    function track_statusbuff(st, inst=0)
        Hashpipe.status_attach(inst, Ref(st))
        st_array = unsafe_wrap(Array, st.p_buf,
                    (Hashpipe.STATUS_RECORD_SIZE, Hashpipe.STATUS_TOTAL_SIZE÷Hashpipe.STATUS_RECORD_SIZE))
        return StringView.(eachcol(st_array))
    end

    function getStatus(st, field, inst=0, type=Int)
        stsv = track_statusbuff(st, inst)
        Hashpipe.status_buf_lock_unlock(Ref(st)) do
            return parse(type, @view stsv[findfirst(startswith(field), stsv)][10:end])
        end
    end

    function getnblkin(st, inst=0, piperblk = 16384, nblocks = 24)
        # attempt to access NULBLKIN field
        try return getStatus(st, "NULBLKIN", inst)
        catch
            # if NULBLKIN field does not exist, calculate using PKTIDX
            return getStatus(st, "PKTIDX", inst) ÷ piperblk % nblocks
        end
    end
end
