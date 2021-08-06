using WebIO, Mux

s = Scope()
s(dom"div.status_buffer"())
obs = Observable(s, "sbobs", "fubar!")

#=
timestr() = Dates.format(now(), "HH:MM:SS")

# Update the time every second
@async while true
    time[] = timestr()
    sleep(1)
end
=#

# Setup a JavaScript listener
onjs(
    s, "sbobs",
    js"""
    function(s) {
        alert(s);
        #this.dom.querySelector(".status_buffer").inner_html = s;
    }
    """
)

WebIO.webio_serve(page("/", req->s.dom), 8001)
