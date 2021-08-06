module HashpipeUtils
    using Hashpipe, FFTW

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

    function detect(raw_data)
        return abs2.(convert(Array{Complex{Float32}}, raw_data))
    end

    function integrate(power, dim = 2)
        shape = size(power)
        return reshape(sum(power, dims = 2), (shape[1], shape[3])) #how to reshape more generally (when not using dim=2)
    end

    function compute_pwr(raw_data, avg=true, dim =2)
        pwr = sum(compute_mag(raw_data), dims=dim)
        if avg
            nt = size(raw_data)[dim]
            return pwr/nt
        else 
            return pwr
        end
    end

    # function compute_intvlpwr(raw_data, t1, t2, avg = true, dim = 2)
    #     nt = t2-t1
    #     compute_pwr(raw_data[:, (t1:t2), :], nt, avg, dim)
    # end

    function compute_singlepwr(raw_data, idx)
        return compute_mag(@view raw_data[:, idx, :])
    end

    function hashpipe_fft(raw_data::Array{Complex{Int8}, 3}, nf, chan)
        np, nt, nc = size(raw_data)
        reshaped = @view reshape(raw_data, (np, nf, nt÷nf, nc))[:, :, :, chan]
        transformed = fft(reshaped, 2)
        return fftshift(transformed, 2) #(np, nf, nt/nf, nchans)
    end

    function remove_DCspike(pwr_array)
        n = size(pwr_array)[2]
        pwr_array[:,n÷2 + 1] = ((@view pwr_array[:,n÷2]) + (@view pwr_array[:,n÷2 + 2]))/2
    end
end