using HPGuppiDaq
using Hashpipe
using Plots

ENV["HASHPIPE_KEYFILE"]="/home/davidm"

# load in data
inst, nbuff, nblocks = (0, 2, 24)
np, nt, nc = (2, 512*1024, 64)
blks = HPGuppiDaq.HashpipeUtils.track_databuffer((inst, nbuff, nblocks), (np, nt, nc))

# status buffer
shmid, p_lock, p_buf = 0,0,0
st = Hashpipe.status_t(inst, shmid, p_lock, p_buf)

# display of FFT
function plot_fft(pwr)
    l1 = @layout [a ; b]
    p1 = plot(pwr[1,:], title = "Pol 1. Coarse Channel 46")
    p2 = plot(pwr[2,:], title = "Pol 2. Coarse Channel 46")

    p = plot(p1, p2, layout = l1, legend = false, titlefontsize=10,
             xlabel = "Channel", ylabel="average power")
    
    display(p)
end

HPGuppiDaq.HashpipeApps.FFTread(blks, 5, 46, plot_fft, st, 128)