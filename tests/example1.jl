include("../HashpipeUtils.jl")
include("../DataBuffFFT.jl")
include("../StatusBuff.jl")
using .HashpipeUtils, .DataBuffFFT, .StatusBuff

# attach to data buffer & get data in blocks
blks = HashpipeUtils.track_databuffer((0, 2, 24), (2, 512*1024, 64))

# attach to status buffer
st = Hashpipe.status_t(0,0,0,0)

# create circular array to store spectra
# https://juliahub.com/ui/Packages/CircularArrayBuffers/HOj1r/0.1.2
spectra = CircularArrayBuffer{Array{Float32, 2}}(5)

DataBuffFFT.FFTread(blks, spectra, 7, st)
