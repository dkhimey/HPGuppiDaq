include("HashpipeUtils.jl")
using .HashpipeUtils, Blio, Plots, FFTW, Statistics

np, nt, nc = (2, 524288, 64) #(polarizations, time samples, coarse channels)
filename = "/datag/davidm/voyager/blc23_guppi_59046_80036_DIAG_VOYAGER-1_0011.0000.raw"
file = open(filename)

# read all blocks
nf = 2^16 #number of fine channels in each coarse channel
chan = 7 #know that voyager signal is in 7th coarse channel

# initialize header and data array
header = read(file, GuppiRaw.Header)
data = Array(header)

# integrated array will hold fft of all 128 blocks
integrated = zeros(Float32, (128, 2,n))
i = 1
seekstart(file) #rewind to the start of the file
while read!(file, header) #read header
    println(i)
    read!(file, data) #read data
    pwr = HashpipeUtils.hashpipe_fft(data, nf, chan) #FFT of data w/ nf channels on 7th coarse channel
    HashpipeUtils.remove_DCspike(pwr) #remove spike
    integrated[i, :, :] = pwr #add to integrated array
    i+=1
end

# plotting
function snapshot_fft(chan)
    fine_pwr = HashpipeUtils.hashpipe_fft(data, 65536, chan)
    HashpipeUtils.remove_DCspike(fine_pwr)

    l1 = @layout [a; b]
    pol1 = fine_pwr[1,:]
    pol2 = fine_pwr[2,:]
    p1 = plot(pol1, title="Chan"*string(chan), label="Pol. 1",
            ylims=(minimum(pol1)-std(pol1), maximum(pol1)))
    p2 = plot(pol2, label="Pol. 2",
            ylims=(minimum(pol2)-std(pol2), maximum(pol2)))
    f = plot(p1, p2, layout = l1, titlefontsize=10, 
            xlabel="Channel", ylabel="power", legend=:topleft)

    return display(f)
end

# plot(integrated[:, 1, 40000:42500])
# waterfall = integrated[:,1,:]
# heatmap(1:size(waterfall,1), 1:size(waterfall,2), waterfall)
# last5 = sum(integrated[124:128, 1, :], dims=1)
# first5 = sum(integrated[1:5, 1, :], dims=1)
# heatmap(log10.(@view waterfall[:, 40000:42500]))
