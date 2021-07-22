module HashpipeCalculations
    using Hashpipe, FFTW

    function track_databuffer((inst, nbuff, nblock), 
                            (np, nt, nc))
        ENV["HASHPIPE_KEYFILE"]="/home/davidm"
        # attach to data buffer
        pdb = Hashpipe.hashpipe_databuf_attach(inst, nbuff)
        # pointer to data block
        pb = Hashpipe.hashpipe_databuf_data(pdb, nblock)
        # cast data to complex integers; offset by 2560*80 for header
        pz = Ptr{Complex{Int8}}(pb+2560*80)
        # data
        return unsafe_wrap(Array, pz, (np, nt, nc))
    end

    function compute_mag(raw_data)
        return abs2.(Complex{Float32}.(raw_data))
    end

    function compute_pwr(raw_data, nt, avg=true, dim =2)
        pwr = sum(compute_mag(raw_data), dims=dim)
        if avg
            return pwr/nt
        else 
            return pwr
        end
    end

    function compute_intvlpwr(raw_data, t1, t2, avg = true, dim = 2)
        nt = t2-t1
        compute_pwr(raw_data[:, (t1:t2), :], nt, avg, dim)
    end

    function compute_singlepwr(raw_data, idx)
        return compute_mag(raw_data[:, idx, :])
    end

    function hashpipe_fft(raw_data, np, nt, nc)
        transformed = fft(reshape(raw_data, (np, 128, Int(nt/128), nc)), 2)
        shifted = fftshift(transformed, 2)
        total_pwr = compute_pwr(shifted, 1, false, 3)
        return reshape(total_pwr, (np,128*nc))
    end

end