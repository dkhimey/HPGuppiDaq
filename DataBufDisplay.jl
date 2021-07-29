module Display
using .HashpipeCalculations, Plots, Statistics

    inst, nbuff, nblock = 0, 2, 0
    np, nt, nc = 2, 512*1024, 64
    data = HashpipeCalculations.track_databuffer((inst, nbuff, nblock), (np, nt, nc))

    # snapshot_xxx functions return plots
    function snapshot_power()
        avg_pwr = HashpipeCalculations.compute_pwr(data, nt)

        l1 = @layout [a ; b]
        pol1 = avg_pwr[1,1,:]
        pol2 = avg_pwr[2,1,:]
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
        avg_pwr = HashpipeCalculations.compute_pwr(data, nt)
        interval_pwr = HashpipeCalculations.compute_intvlpwr(data, 1, 1000)
        single_pwr = HashpipeCalculations.compute_singlepwr(data, 1)

        l = @layout [a;b;c]
        t1 = plot(avg_pwr[1,1,:], title = "1st Polarization",
                ylims = ylims=(minimum(avg_pwr[1,1,:])-std(avg_pwr[1,1,:]), maximum(avg_pwr[1,1,:])))
        i1 = plot(interval_pwr[1,1,:])
        s1 = plot(single_pwr[1,:])
        p1 = plot(t1, i1, s1, layout=l, legend=false)

        l = @layout [a;b;c]
        t2 = plot(avg_pwr[2,1,:], title = "2nd Polarization",
                ylims = ylims=(minimum(avg_pwr[2,1,:])-std(avg_pwr[2,1,:]), maximum(avg_pwr[2,1,:])))
        i2 = plot(interval_pwr[2,1,:])
        s2 = plot(single_pwr[2,:])
        p2 = plot(t2, i2, s2, layout=l, legend=false)

        l = @layout [a b]
        return plot(p1, p2, layout=l)
    end

    function snapshot_fft()
        avg_pwr = HashpipeCalculations.compute_pwr(data, nt)
        fine_pwr = HashpipeCalculations.hashpipe_fft(data, 128, np, nt, nc, 8)

        l1 = @layout [a; b]
        pol1 = avg_pwr[1,1,:]
        pol2 = avg_pwr[2,1,:]
        p1 = plot(pol1, title="Native Channelization (64 coarse chan.)", 
                    label="Pol. 1",
                ylims=(minimum(pol1)-std(pol1), maximum(pol1)))
        p2 = plot(pol2, label="Pol. 2",
                ylims=(minimum(pol2)-std(pol2), maximum(pol2)))
        r = plot(p1, p2, layout = l1, titlefontsize=10, 
        xlabel="Channel", ylabel="avg power")

        l1 = @layout [a; b]
        pol1 = fine_pwr[1,:]
        pol2 = fine_pwr[2,:]
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
end