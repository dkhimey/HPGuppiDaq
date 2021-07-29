using Hashpipe
ENV["HASHPIPE_KEYFILE"]="/home/davidm"

st = Hashpipe.status_t(0,0,0,0)
Hashpipe.status_attach(0, Ref(st))

nblkin=String(fill(0x0, 80))
Hashpipe.hgets(st.p_buf, "NULBLKIN", 80, pointer(nblkin))
parse(Int, strip(nblkin, '\0'))

[Hashpipe.hgets(st.p_buf, "NULBLKIN", 80, pointer(nblkin)) for i = 1:10]

module StatusBuf
    function getnblkin(st, nblkin)
        Hashpipe.hgets(st.p_buf, "NULBLKIN", 80, pointer(nblkin))
        parse(Int, strip(nblkin, '\0'))
    end
end

# 187*24