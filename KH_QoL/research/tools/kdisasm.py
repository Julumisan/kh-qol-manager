import sys, pickle
sys.path.insert(0, r"C:\Program Files (x86)\Steam\steamapps\common\KINGDOM HEARTS -HD 1.5+2.5 ReMIX-\KH_QoL\research\pydeps")
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_64
pe = pefile.PE(r"C:\Program Files (x86)\Steam\steamapps\common\KINGDOM HEARTS -HD 1.5+2.5 ReMIX-\KINGDOM HEARTS FINAL MIX.exe")
IB = pe.OPTIONAL_HEADER.ImageBase
md = Cs(CS_ARCH_X86, CS_MODE_64); md.skipdata=True
out=[]
for s in pe.sections:
    if not s.IMAGE_SCN_MEM_EXECUTE: continue
    data=s.get_data(); base=s.VirtualAddress
    for (addr,size,mn,op) in md.disasm_lite(data, base):
        out.append((addr,size,mn,op))
pickle.dump(out, open(sys.argv[1],"wb"))
print(len(out))
