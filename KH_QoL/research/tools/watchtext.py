import sys,os,time,struct; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from live import Proc
p=Proc(); last=None; t0=time.time()
while time.time()-t0 < 900:
    try: raw=p.rd(0x22EC100,0x40)
    except OSError: print("game closed", flush=True); break
    if raw!=last:
        fl=struct.unpack("<16f",raw)
        print(" ".join(f"{x:.3g}" for x in fl), flush=True)
    last=raw; time.sleep(0.01)
