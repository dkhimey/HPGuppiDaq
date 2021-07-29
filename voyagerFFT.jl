include("calculations.jl")
using .HashpipeCalculations, Blio, Plots, FFTW, Statistics

np, nt, nc = (2, 524288, 64)
filename = "/datag/davidm/voyager/blc23_guppi_59046_80036_DIAG_VOYAGER-1_0011.0000.raw"
file = open(filename)

# read all blocks
n = 2^16
chan = 7
header = read(file, GuppiRaw.Header)
data = Array(header)

integrated = zeros(Float32, (128, 2,n))
i = 1

seekstart(file)
while read!(file, header)
    println(i)
    read!(file, data)
    pwr = HashpipeCalculations.hashpipe_fft(data, n, chan)
    HashpipeCalculations.remove_DCspike(pwr)
    integrated[i, :, :] = pwr
    i+=1
end

# plotting
function snapshot_fft(chan)
    fine_pwr = hashpipe_fft(data, 65536, chan)
    fine_pwr[:, Int(4096/2+1)] = (fine_pwr[:, Int(4092/2)] + fine_pwr[:, Int(4092/2+2)])/2

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
