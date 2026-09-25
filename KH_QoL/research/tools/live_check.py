import struct, sys; sys.path.insert(0, sys.argv[1])
from live import Proc
p=Proc(); print("pid",p.pid,"base",hex(p.base))
for a in (0x2AC313,0x2AC31F,0x2AC32B): print("munny imm",hex(a),p.rd(a,5).hex(" "))
for a in (0x2AB4E1,0x2AB539,0x2AC145):
    d=struct.unpack("<i",p.rd(a+4,4))[0]; print("load",hex(a),"->",hex(a+8+d))
for a in (0x3EF6C8,0x3EF6CC,0x3EF6D0,0x3EDE28,0x2F13FF0): print("float",hex(a),p.f(a))
print("exp",p.f(0x2D5CB00),"jackpot",p.f(0x2D60FA4),"lucky",p.f(0x2D60FA8))
print("hp",p.i(0x2D5CC4C),"maxhp(int+4)",p.i(0x2D5CC50),"mp",p.i(0x2D5CC54),"lvl",p.b(0x2DE9364),"maxhp",p.b(0x2DE9366),"hud",p.f(0x281249C))
ptr=struct.unpack("<Q",p.rd(0x2E1F4D8,8))[0]; print("munny ptr",hex(ptr), "rva", hex(ptr-p.base) if ptr else None, "munny", p.i(ptr-p.base+0x1C) if ptr else None, "munny@0x2DFF77C", p.i(0x2DFF77C))
