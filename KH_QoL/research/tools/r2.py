from q import *
import sys
lo,hi=int(sys.argv[1],16),int(sys.argv[2],16)
for k,t in refs(lo,hi):
    print("=====",hex(t)); show(k,int(sys.argv[3]),int(sys.argv[3]))
