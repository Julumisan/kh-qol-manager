from q import *
import sys
for t in sys.argv[1:]:
    t=int(t,16)
    print("== callers of",hex(t))
    for k,i in enumerate(ins):
        if i[2] in("call","jmp") and i[3]==hex(t):
            # find function start: previous int3 run
            j=k
            while j>0 and ins[j-1][2]!="int3": j-=1
            print(f"  {i[0]:08X} {i[2]} (func ~{ins[j][0]:08X})")
