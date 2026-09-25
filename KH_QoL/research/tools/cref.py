from q import *
from collections import Counter
import sys
w=[int(x,16) for x in sys.argv[1:]]
c=Counter()
for k,i in enumerate(ins):
    t=tgt(i)
    if t in w: c[t]+=1; print(hex(t), f"{i[0]:08X} {i[2]} {i[3]}")
print(c)
