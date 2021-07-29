include("calculations.jl")
using .HashpipeCalculations, Plots, FFTW

inst, nbuff, nblock = 0, 2, 0
np, nt, nc = 2, 512*1024, 64

data = track_databuffer((inst, nbuff, nblock), (np, nt, nc))
fft = HashpipeCalculations.hashpipe_fft(data, np. nt, nc)