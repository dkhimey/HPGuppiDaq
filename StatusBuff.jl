module StatusBuff
    using Hashpipe

    # st = Hashpipe.status_t(0,0,0,0)
    # Hashpipe.status_attach(0, Ref(st))

    function getStatus(st, field, type=Int)
        Hashpipe.status_buf_lock_unlock(Ref(st)) do
            parse(type, @view stsv[findfirst(startswith(field), stsv)][10:end])
        end
    end

    function getnblkin(st)
        # attempt to access NULBLKIN field
        try return getStatus(st, "NULBLKIN")
        catch
            # if NULBLKIN field does not exist, calculate using PKTIDX
            return getStatus(st, "PKTIDX") ÷ 16384 % 24
        end
    end

    # SLOWER
    # function getStatusFIeld(st, field, type=Int)
    #     nblkin=String(fill(0x0, 80))
    #     Hashpipe.status_buf_lock_unlock(Ref(st_struct)) do
    #         Hashpipe.hgets(st.p_buf, field, 80, pointer(nblkin))
    #         return parse(type, strip(nblkin, '\0'))
    #     end
    # end
end