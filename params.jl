struct Params
    inst::Int
    nbuff::Int
    np::Int
    nt::Int
    nc::Int
    nblocks::Int
end

p = Params(0, 2, 2, 512*1024, 64, 24)