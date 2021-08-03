module StatusBuff
    using Hashpipe, StringViews

    function track_statusbuff(inst)
        st = Hashpipe.status_t(0,0,0,0)
        Hashpipe.status_attach(inst, Ref(st))
        st_array = unsafe_wrap(Array, st.p_buf,
                    (Hashpipe.STATUS_RECORD_SIZE, Hashpipe.STATUS_TOTAL_SIZE÷Hashpipe.STATUS_RECORD_SIZE))
        return StringView.(eachcol(st_array))
    end

    function getStatus(stsv, field, type=Int)
        Hashpipe.status_buf_lock_unlock(Ref(st)) do
            return parse(type, @view stsv[findfirst(startswith(field), stsv)][10:end])
        end
    end

    function getnblkin(stsv)
        # attempt to access NULBLKIN field
        try return getStatus(stsv, "NULBLKIN")
        catch
            # if NULBLKIN field does not exist, calculate using PKTIDX
            return getStatus(stsv, "PKTIDX") ÷ 16384 % 24
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