module RedisDisplay
using Plots, Statistics
    function snapshot_power(avg_pwr)
        # size(avg_pwr) == (2,1,64)

        l1 = @layout [a ; b]
        pol1 = avg_pwr[1,1,:]
        pol2 = avg_pwr[2,1,:]
        p1 = plot(pol1, title="Pol. 1, Total Power", 
                ylims=(minimum(pol1)-std(pol1), maximum(pol1)))
        p2 = plot(pol2, title="Pol. 2, Total Power",
                ylims=(minimum(pol2)-std(pol2), maximum(pol2)))
        p = plot(p1, p2, layout = l1, legend = false, titlefontsize=10, 
                xlabel="Channel", ylabel="avg power")

        # l1 = @layout [a ; b]
        # h1 = histogram(real.(data[1,:,1]))
        # h2 = histogram(real.(data[2,:,1]))
        # h = plot(h1, h2, layout = l1, legend = false, xlabel="Re(voltage)")

        # l2 = @layout [a{0.7w} b]
        # return plot(p, h, layout = l2)
        return p
    end

    function display_power(avg_pwr, t = .5)
        i = 0
        while true
            println(i)
            display(snapshot_power(avg_pwr))
            i+=1
            sleep(t)
        end
    end
end