import sys, os, pickle, re, bisect
ins = pickle.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),"kh1.pkl"),"rb"))
addrs=[i[0] for i in ins]
rx=re.compile(r"\[rip ([+-]) (0x[0-9a-f]+)\]")
def tgt(i):
    m=rx.search(i[3])
    if not m: return None
    d=int(m.group(2),16); d = d if m.group(1)=='+' else -d
    return i[0]+i[1]+d
def refs(lo,hi):
    r=[]
    for k,i in enumerate(ins):
        t=tgt(i)
        if t is not None and lo<=t<hi: r.append((k,t))
    return r
def show(k,before=10,after=10,mark=None):
    for j in range(max(0,k-before),min(len(ins),k+after+1)):
        a,s,mn,op=ins[j]
        t=tgt(ins[j])
        print(("> " if j==k else "  ")+f"{a:08X} {mn:8} {op}"+(f"   ; ->{t:X}" if t else ""))
def at(rva):
    return bisect.bisect_left(addrs,rva)
