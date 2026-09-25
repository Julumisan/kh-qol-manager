import sys,os,time,struct; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from live import Proc
p=Proc(); last=None; lastl=None; lasthp=None; t0=time.time()
while time.time()-t0 < 1800:
    try:
        m=p.i(0x2DFF77C); l=round(p.f(0x2D60FA8),3); e=round(p.f(0x2D5CB00),3)
    except OSError:
        print("game closed", flush=True); break
    if last is not None and m!=last:
        d=m-last; print(f"munny {last} -> {m} ({d:+d}) {'OK multiplo de 3' if d>0 and d%3==0 else ''}", flush=True)
    if lastl is not None and l!=lastl: print(f"lucky {lastl} -> {l} exp {e}", flush=True)
    hp=p.i(0x2D5CC4C)
    if lasthp is not None and hp>lasthp: print(f"HP {lasthp} -> {hp} (orbe/cura)", flush=True)
    lasthp=hp; last=m; lastl=l; time.sleep(0.1)
