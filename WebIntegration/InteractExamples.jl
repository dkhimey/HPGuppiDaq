module InteractExamples

using Interact
using Mux
using OrderedCollections
using Redis
using Plots
using PrettyTables
#using TableView

const REDIS = Ref{RedisConnection}()

function redis()
    if !isassigned(REDIS)
        REDIS[] = RedisConnection(host="redishost")
    end
    REDIS[]
end

function maketable(conn, instance="blc00/0")
    st = hgetall(conn, "srt://$instance/status") |> OrderedDict
    sort!(st)
    #TableView.showtable(st)
    #TableView.showtable(rand(10,2))
    pretty_table(String, st,
        #backend=:html,
        tf=tf_html_default,
        noheader=:true,
        standalone=false,
        title=instance
    )
end

maketablehtml(conn) = maketable(conn) |> HTML
# connect to redis
conn = RedisConnection(host="blh0")
sub = open_subscription(conn)
const UI = Ref{Any}()

observable = Observable(0)
function f()
    observable += 1
end

function ui()
    if !isassigned(UI)
        subscribe(sub, "chan-srt://blc00/0/spectra", f)
        refreshbutton = button("Refresh")
        # throttle(10, refreshbutton) # doesn't work

        myplot = Observable{Any}(plot(rand(10), ylims=(0,1)))
        map!(_->plot(rand(10), ylims=(0,1)), myplot, observable)

        ## This works
        #tablenode = Observable{Any}(maketablenode(redis()))
        #map!(_->maketablenode(redis()), tablenode, refreshbutton)

        # This also works and doesn't create a new node each update
        # tablehtml = Observable{HTML{String}}(maketablehtml(redis()))
        # tablenode = Observable{Any}(node(:div, tablehtml))
        # map!(_->maketablehtml(redis()), tablehtml, refreshbutton)

        UI[] = dom"div"(refreshbutton, myplot)
    end
    UI[]
end

function serve(port=8000)
    WebIO.webio_serve(page("/", req -> ui()), port)
end

end # module

InteractExamples.serve(8021)