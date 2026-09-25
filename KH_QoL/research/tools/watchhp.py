import sys,os,time; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from live import Proc
p=Proc(); last=None; t0=time.time()
while time.time()-t0 < 1500:
    try: hp=p.i(0x2D5CC4C); mx=p.i(0x2D5CC50); mp=p.i(0x2D5CC54); mmx=p.i(0x2D5CC58); spd=round(p.f(0x2D5CC18),3)
    except OSError: print("game closed", flush=True); break
    cur=(hp,mx,mp,mmx,spd)
    if cur!=last: print(f"HP {hp}/{mx}  MP {mp}/{mmx}  vel {spd}", flush=True)
    last=cur; time.sleep(0.05)
