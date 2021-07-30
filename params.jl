struct Params
    inst::Int = 0
    nbuff::Int = 2
    np::Int = 2
    nt::Int = 524288
    nc::Int = 64
    nblocks::Int = 24
end

params = Params(0, 2, 2, 512*1024, 64, 24)