from q import *
import sys
a=int(sys.argv[1],16); b=int(sys.argv[2],16)
k=at(a)
while ins[k][0]<b:
    x=ins[k]; t=tgt(x)
    print(f"{x[0]:08X} {x[2]:8} {x[3]}"+(f"   ; ->{t:X}" if t else "")); k+=1
