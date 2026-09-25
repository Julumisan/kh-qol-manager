# Samples dialogue-related memory while text is being revealed and ranks
# addresses that behave like a per-character counter.
import sys, os, time, struct
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from live import Proc
p = Proc()
REGIONS = [(0x22EC000, 0x2000), (0x232D000, 0x2000), (0x23D0000, 0x8000), (0x2998000, 0x8000), (0x2380000, 0x4000)]
dur = float(sys.argv[1]) if len(sys.argv) > 1 else 25
samples = {r: [] for r in REGIONS}
t0 = time.time(); n = 0
while time.time() - t0 < dur:
    for r in REGIONS:
        try: samples[r].append(np.frombuffer(p.rd(r[0], r[1]), dtype=np.int32).copy())
        except OSError: pass
    n += 1; time.sleep(0.015)
print("samples", n)
res = []
for (base, size), arr in samples.items():
    a = np.array(arr)                     # [t, words]
    d = np.diff(a, axis=0)
    inc = (d > 0) & (d <= 4)              # small integer increments
    dec = d < 0
    nchg = (d != 0).sum(0)
    for w in np.where((inc.sum(0) >= 15) & (dec.sum(0) >= 1) & (dec.sum(0) <= 40))[0]:
        col = a[:, w]
        res.append((inc[:, w].sum(), base + 4 * w, int(col.min()), int(col.max()), int(dec[:, w].sum()), int(nchg[w])))
    # float counters
    f = a.view(np.float32)
    fd = np.diff(f, axis=0)
    finc = (fd > 0) & (fd < 8) & np.isfinite(fd)
    fdec = fd < 0
    for w in np.where((finc.sum(0) >= 15) & (fdec.sum(0) >= 1) & (fdec.sum(0) <= 40))[0]:
        col = f[:, w]
        res.append((finc[:, w].sum(), base + 4 * w, float(np.nanmin(col)), float(np.nanmax(col)), int(fdec[:, w].sum()), -1))
res.sort(reverse=True)
for r in res[:40]:
    print("incs=%d addr=0x%X min=%s max=%s resets=%d" % (r[0], r[1], r[2], r[3], r[4]))
