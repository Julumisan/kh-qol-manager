import ctypes, struct, sys
from ctypes import wintypes
k=ctypes.WinDLL("kernel32",use_last_error=True); ps=ctypes.WinDLL("psapi",use_last_error=True)
k.OpenProcess.restype=wintypes.HANDLE
k.ReadProcessMemory.argtypes=(wintypes.HANDLE,wintypes.LPCVOID,wintypes.LPVOID,ctypes.c_size_t,ctypes.POINTER(ctypes.c_size_t))
def find_pid(name):
    import subprocess
    out=subprocess.run(["tasklist","/FO","CSV","/NH"],capture_output=True,text=True).stdout
    for l in out.splitlines():
        p=l.strip('"').split('","')
        if p[0].lower()==name.lower(): return int(p[1])
class Proc:
    def __init__(s,name="KINGDOM HEARTS FINAL MIX.exe"):
        s.pid=find_pid(name); s.h=k.OpenProcess(0x0410,False,s.pid)
        mods=(wintypes.HMODULE*1024)(); need=wintypes.DWORD()
        ps.EnumProcessModules.argtypes=(wintypes.HANDLE,ctypes.POINTER(wintypes.HMODULE),wintypes.DWORD,ctypes.POINTER(wintypes.DWORD))
        ps.EnumProcessModules(s.h,mods,ctypes.sizeof(mods),ctypes.byref(need)); s.base=mods[0]
    def rd(s,rva,n,absolute=False):
        b=ctypes.create_string_buffer(n); d=ctypes.c_size_t()
        if not k.ReadProcessMemory(s.h,(rva if absolute else s.base+rva),b,n,ctypes.byref(d)): raise OSError(ctypes.get_last_error())
        return b.raw
    def f(s,rva): return struct.unpack("<f",s.rd(rva,4))[0]
    def i(s,rva): return struct.unpack("<i",s.rd(rva,4))[0]
    def b(s,rva): return s.rd(rva,1)[0]
