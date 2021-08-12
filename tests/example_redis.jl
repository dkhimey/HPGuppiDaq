using HPGuppiDaq, Hashpipe

# !!specify path to Hashpipe Keyfile!!
ENV["HASHPIPE_KEYFILE"]="/home/davidm"

# attach to data buffer
inst, nbuff, nblocks = (0, 2, 24)
np, nt, nc = (2, 512*1024, 64)
# grab data in blocks
blks = HPGuppiDaq.HashpipeUtils.track_databuffer((inst, nbuff, nblocks), (np, nt, nc))

# attach to status buffer
shmid, p_lock, p_buf = 0,0,0
st = Hashpipe.status_t(inst, shmid, p_lock, p_buf)

# grab fields in status buffer
status = HPGuppiDaq.HashpipeUtils.track_statusbuff(st)

