import sys, os, struct, shutil, pathlib
"""Offline harness: runs the real KH1 Lua scripts in Lua 5.4 (lupa) against a
memory image built from the installed EXE, with LuaBackend's API mocked."""
HERE = pathlib.Path(__file__).resolve().parent
GAME = HERE.parents[2]
sys.path.insert(0, str(GAME / "KH_QoL" / "research" / "pydeps"))
import pefile, lupa.lua54 as lua54

BASE = 0x140000000
HASH = "D790746245D26159F3EE0E1060E33B2FA2DE06941850A4AC724F598722884BAC"

def load_image():
    pe = pefile.PE(str(GAME / "KINGDOM HEARTS FINAL MIX.exe"))
    mem = bytearray(pe.OPTIONAL_HEADER.SizeOfImage)
    for s in pe.sections:
        raw = s.get_data()[: max(s.SizeOfRawData, 0)]
        n = min(len(raw), s.Misc_VirtualSize)
        mem[s.VirtualAddress : s.VirtualAddress + n] = raw[:n]
    return mem

IMAGE = load_image()

class Game:
    def __init__(self):
        self.mem = bytearray(IMAGE)
        self.writes = []
    # helpers
    def rf(self, a): return struct.unpack_from("<f", self.mem, a)[0]
    def wf(self, a, v): struct.pack_into("<f", self.mem, a, v)
    def ri(self, a): return struct.unpack_from("<I", self.mem, a)[0]
    def wi(self, a, v): struct.pack_into("<I", self.mem, a, v & 0xFFFFFFFF)
    def set_loaded_save(self, munny=500):
        self.mem[0x2DE9366] = 20      # max hp
        self.mem[0x2DE9364] = 10      # level
        self.wi(0x2D5CC4C, 20)        # runtime hp
        self.wf(0x281249C, 1.0)       # hud
        struct.pack_into("<Q", self.mem, 0x2E1F4D8, BASE + 0x2DFF760)
        self.wi(0x2DFF77C, munny)
        self.set_item_table(0x2D24798)
        # battle parameter table: Sora jump words (+0x54 normal, +0x56 alternate)
        struct.pack_into("<Q", self.mem, 0x2D22D30, BASE + 0x2D40000)
        struct.pack_into("<HH", self.mem, 0x2D40000 + 0x54, 290, 350)
        self.wf(0x2D5CC10 + 0x10, 290.0)
    def set_item_table(self, rva):
        struct.pack_into("<Q", self.mem, 0x2D22D38, BASE + rva)
        for i in range(255):
            struct.pack_into("<HH", self.mem, rva + i * 20 + 8, 20 + i * 10, 10 + i * 5)  # buy, sell
    def sell(self, rva, i): return struct.unpack_from("<H", self.mem, rva + i * 20 + 0xA)[0]
    def buy(self, rva, i): return struct.unpack_from("<H", self.mem, rva + i * 20 + 8)[0]
    def recompute(self, exp=1.0, jackpot=1.0, lucky=1.0):
        self.wf(0x2D5CB00, exp); self.wf(0x2D60FA4, jackpot); self.wf(0x2D60FA8, lucky)

def make_runtime(game_dir, **cfg):
    d = {"preset": "Test", "build_hash": HASH, "build_authorized": True,
         "exp_multiplier": 1, "munny_multiplier": 1, "drop_multiplier": 1, "pickup_radius_multiplier": 1,
         "movement_speed_multiplier": 1, "infinite_hp": False, "infinite_mp": False, "automatic_pickup": False,
         "multiply_shop_sales": False, "faster_text": False, "instant_gummi": False}
    d.update(cfg)
    def v(x):
        if isinstance(x, bool): return "true" if x else "false"
        if isinstance(x, str): return '"%s"' % x
        return repr(x)
    body = "return {\n" + "".join(f"  {k} = {v(x)},\n" for k, x in d.items()) + "}\n"
    (game_dir / "scripts/kh1/io_packages/kh_qol/runtime.lua").write_text(body, encoding="utf-8")

def setup_tree(tmp):
    tmp = pathlib.Path(tmp)
    if tmp.exists(): shutil.rmtree(tmp)
    shutil.copytree(GAME / "KH_QoL/scripts/kh1", tmp / "scripts/kh1")
    (tmp / "logs").mkdir(parents=True)
    return tmp

class Script:
    """One LuaBackend script instance bound to a Game."""
    def __init__(self, game, tree, game_id=0xAF71841E):
        self.g = game
        L = lua54.LuaRuntime(unpack_returned_tuples=True)
        self.L = L
        g = L.globals()
        m = game
        def rng(a, n=1):
            if a < 0 or a + n > len(m.mem): raise RuntimeError("out of image 0x%X" % a)
        def ab(a):
            r = a - BASE; rng(r); return r
        g.SCRIPT_PATH = str((tree / "scripts/kh1").as_posix())
        g.GAME_ID = game_id
        g.ConsolePrint = lambda *a: None
        g.ReadByte = lambda a: (rng(a), m.mem[a])[1]
        g.ReadShort = lambda a: struct.unpack_from("<H", m.mem, a)[0]
        def wshort(a, v): rng(a,2); struct.pack_into("<H", m.mem, a, v & 0xFFFF); m.writes.append(a)
        g.WriteShort = wshort
        def wlong(a, v): rng(a,8); struct.pack_into("<Q", m.mem, a, v & 0xFFFFFFFFFFFFFFFF); m.writes.append(a)
        g.WriteLong = wlong
        g.ReadShortA = lambda a: struct.unpack_from("<H", m.mem, ab(a))[0]
        def wsa(a, v): struct.pack_into("<H", m.mem, ab(a), v & 0xFFFF); m.writes.append(ab(a))
        g.WriteShortA = wsa
        g.ReadInt = lambda a: (rng(a,4), m.ri(a))[1]
        g.ReadLong = lambda a: struct.unpack_from("<Q", m.mem, a)[0]
        g.ReadFloat = lambda a: (rng(a,4), m.rf(a))[1]
        def read_array(a, n):
            rng(a, n); return L.table_from([m.mem[a + i] for i in range(n)])
        g.ReadArray = read_array
        def wbyte(a, v): rng(a); m.mem[a] = v & 0xFF; m.writes.append(a)
        g.WriteByte = wbyte
        def wint(a, v): rng(a,4); m.wi(a, v); m.writes.append(a)
        g.WriteInt = wint
        def wfloat(a, v): rng(a,4); m.wf(a, v); m.writes.append(a)
        g.WriteFloat = wfloat
        def warray(a, t):
            vals = [t[i] for i in range(1, len(t) + 1)]
            rng(a, len(vals))
            for i, v in enumerate(vals): m.mem[a + i] = v & 0xFF
            m.writes.append(a)
        g.WriteArray = warray
        g.ReadIntA = lambda a: m.ri(ab(a))
        def wia(a, v): m.wi(ab(a), v); m.writes.append(ab(a))
        g.WriteIntA = wia
        src = (tree / "scripts/kh1/main.lua").read_text(encoding="utf-8")
        L.execute(src)
        self.g_ = g
    def init(self): self.g_._OnInit()
    def frames(self, n):
        for _ in range(n): self.g_._OnFrame()
