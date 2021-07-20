using Interact,Plots,Mux
using Hashpipe

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

function myModel(p)
    # xrange = collect(-50:+50)
    # model = p1.*xrange .+ p2.* (xrange) .^2
    # return model
    total_pwr = (sum(abs2.(Complex{Int32}.(data)), dims=2)[:, 1, :])/nt
    return total_pwr[1,:]
end

function createLayout()
#   p1s = slider(-50:50, label = "Par#1 (linear term):", value = 1)
#   p2s = slider(-5:0.1:5, label = "Par#2 (quad term):", value = 1)
  b = button("Update!")
  o = observe(b)
#   on(n -> println, o)

  mOutput = Interact.@map myModel(&b)
  plt = Interact.@map plot(collect(1:64),&mOutput, label="Power", xlabel="Channel")
#   wdg = Widget(["p1" => p1s, "p2" => p2s, "btn" => b], output = mOutput)
  wdg = Widget(["btn" => b], output = mOutput)
  @layout! wdg hbox(plt, vbox(:btn))
#   @layout! wdg hbox(plt, vbox(:p1, :p2, :btn))
end

function serveLayout(port)
    try
      WebIO.webio_serve(page("/", req -> createLayout()), port)
    catch e
      if isa(e, IOError)
        # sleep and then try again
        sleep(0.1)
        serveLayout(port)
      else
        throw(e)
      end
    end
end

serveLayout(8000)