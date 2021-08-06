module HPGuppiDaq
    using Hashpipe
    using FFTW
    using Statistics
    using Redis

    include("DataBufDisplay.jl")
    include("HashpipeUtils.jl")
    include("DataBuffFFT.jl")
    include("DataFromRedis.jl")
    include("DataToRedis.jl")
    include("RedisDisplay.jl")
    include("StatusBuff.jl")
end