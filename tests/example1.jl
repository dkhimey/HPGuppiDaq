using HPGuppiDaq, Hashpipe

# !!specify path to Hashpipe Keyfile!!
ENV["HASHPIPE_KEYFILE"]="/home/davidm"

# attach to data buffer & grab data in blocks
inst, nbuff, nblocks = (0, 2, 24)
np, nt, nc = (2, 512*1024, 64)
blks = HPGuppiDaq.HashpipeUtils.track_databuffer((inst, nbuff, nblocks), (np, nt, nc))

# attach to status buffer
shmid, p_lock, p_buf = 0,0,0
st = Hashpipe.status_t(inst, shmid, p_lock, p_buf)