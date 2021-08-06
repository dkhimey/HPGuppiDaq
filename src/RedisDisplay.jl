module RedisDisplay
using Plots, Statistics
    function snapshot_power(avg_pwr)
        l1 = @layout [a ; b]
        pol1 = avg_pwr[1,1,:]
        pol2 = avg_pwr[2,1,:]
        p1 = plot(pol1, title="Pol. 1, Total Power", 
                ylims=(minimum(pol1)-std(pol1), maximum(pol1)))
        p2 = plot(pol2, title="Pol. 2, Total Power",
                ylims=(minimum(pol2)-std(pol2), maximum(pol2)))
        p = plot(p1, p2, layout = l1, legend = false, titlefontsize=10, 
                xlabel="Channel", ylabel="avg power")

        return p
    end
end