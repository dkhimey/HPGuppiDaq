module HPGuppiDaq
    using Hashpipe
    using FFTW
    using Statistics
    using Redis

    include("HashpipeUtils.jl")
    include("HashpipeApps.jl")
end