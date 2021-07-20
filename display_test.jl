using Hashpipe, Plots, Statistics, FFTW

ENV["HASHPIPE_KEYFILE"]="/home/davidm"

inst, nbuff, nblock = 0, 2, 0

# attach to data buffer
pdb = Hashpipe.hashpipe_databuf_attach(inst, nbuff)
# pointer to data block
pb = Hashpipe.hashpipe_databuf_data(pdb, nblock)
# cast data to complex integers; offset by 2560*80 for header
pz = Ptr{Complex{Int8}}(pb+2560*80)

# load in data
nc, np, nt = 64, 2, 512*1024
data = unsafe_wrap(Array, pz, (np, nt, nc))

# snapshot_xxx functions return plots
function snapshot_power()
    total_pwr = (sum(abs2.(Complex{Int32}.(data)), dims=2)[:, 1, :])/nt

    l1 = @layout [a ; b]
    pol1 = total_pwr[1,:]
    pol2 = total_pwr[2,:]
    p1 = plot(pol1, title="Pol. 1, Total Power", 
              ylims=(minimum(pol1)-std(pol1), maximum(pol1)))
    p2 = plot(pol2, title="Pol. 2, Total Power",
              ylims=(minimum(pol2)-std(pol2), maximum(pol2)))
    p = plot(p1, p2, layout = l1, legend = false, titlefontsize=10, 
             xlabel="Channel", ylabel="avg power")

    l1 = @layout [a ; b]
    h1 = histogram(real.(data[1,:,1]))
    h2 = histogram(real.(data[2,:,1]))
    h = plot(h1, h2, layout = l1, legend = false, xlabel="Re(voltage)")

    l2 = @layout [a{0.7w} b]
    return plot(p, h, layout = l2)
end

function snapshot_misc()
    data_mag = abs2.(Complex{Int32}.(data))
    total_pwr = (sum(data_mag, dims=2)[:, 1, :])/nt
    interval_pwr = (sum(data_mag[:, 1:1000, :], dims=2)[:, 1, :])/1000
    single_pwr = (data_mag[:, 1, :])

    l = @layout [a;b;c]
    t1 = plot(total_pwr[1,:], title = "1st Polarization",
              ylims = ylims=(minimum(total_pwr[1,:])-std(total_pwr[1,:]), maximum(total_pwr[1,:])))
    i1 = plot(interval_pwr[1,:])
    s1 = plot(single_pwr[1,:])
    p1 = plot(t1, i1, s1, layout=l, legend=false)

    l = @layout [a;b;c]
    t2 = plot(total_pwr[2,:], title = "2nd Polarization",
              ylims = ylims=(minimum(total_pwr[2,:])-std(total_pwr[2,:]), maximum(total_pwr[2,:])))
    i2 = plot(interval_pwr[2,:])
    s2 = plot(single_pwr[2,:])
    p2 = plot(t2, i2, s2, layout=l, legend=false)

    l = @layout [a b]
    return plot(p1, p2, layout=l)
end

function snapshot_fft()
    data_mag = abs2.(Complex{Int32}.(data))
    total_pwr1 = (sum(data_mag, dims=2)[:, 1, :])/nt

    data_reshaped = reshape(data, (np, 128, Int(nt/128), nc))
    transform = fft(data_reshaped, 2)
    shifted = fftshift(transform, 2)
    pwr = abs2.(shifted)
    total_pwr = sum(pwr, dims=3)
    pwr_reshaped = reshape(total_pwr, (np,128*nc))

    l1 = @layout [a; b]
    pol1 = total_pwr1[1,:]
    pol2 = total_pwr1[2,:]
    p1 = plot(pol1, title="Native Channelization (64 coarse chan.)", 
                label="Pol. 1",
              ylims=(minimum(pol1)-std(pol1), maximum(pol1)))
    p2 = plot(pol2, label="Pol. 2",
              ylims=(minimum(pol2)-std(pol2), maximum(pol2)))
    r = plot(p1, p2, layout = l1, titlefontsize=10, 
    xlabel="Channel", ylabel="avg power")

    l1 = @layout [a; b]
    pol1 = pwr_reshaped[1,:]
    pol2 = pwr_reshaped[2,:]
    p1 = plot(pol1, title="Fine Channelization (8192 fine chan.)", label="Pol. 1",
              ylims=(minimum(pol1)-std(pol1), maximum(pol1)))
    p2 = plot(pol2, label="Pol. 2",
              ylims=(minimum(pol2)-std(pol2), maximum(pol2)))
    f = plot(p1, p2, layout = l1, titlefontsize=10, 
             xlabel="Channel", ylabel="power")
    l = @layout [a b]

    return plot(r, f, layout = l, legend=:topleft)
end

# higher order functions
# takes snapshot plotting function and filename and produces a gif
function gif_snapshot(f, filename, n=50)
    anim = @animate for i ∈ 1:n
        f()
    end
    gif(anim, filename)
end

# takes snapshot plotting function and returns a display
function display_snapshot(f, t = .5)
    i = 0
    while true
        println(i)
        display(f())
        i+=1
        sleep(t)
    end
end

# basic display functions
display_power(t = .5) = display_snapshot(snapshot_power, t)
display_misc(t = .5) = display_snapshot(snapshot_misc, t)
display_fft(t = .5) = display_snapshot(snapshot_fft, t)

# gif production functions
gif_power(filename, n=50) = gif_snapshot(snapshot_power, filename, n)
gif_misc(filename, n=50) = gif_snapshot(snapshot_misc, filename, n)
gif_fft(filename, n=100) = gif_snapshot(snapshot_fft, filename, n)

