import struct, sys, pathlib
from harness import *

import tempfile
TMPDIR = pathlib.Path(tempfile.gettempdir()) / "kh_qol_kh1_runtime_test"
fails = []
def check(name, cond, extra=""):
    print(("PASS " if cond else "FAIL ") + name + (("  " + str(extra)) if extra else ""))
    if not cond: fails.append(name)

def f32(x): return struct.unpack("<f", struct.pack("<f", x))[0]
def tagged(v): return (struct.unpack("<I", struct.pack("<f", v))[0] & 0xFF) == 0x5A
def close(a, b, rel=1e-4): return abs(a - b) <= rel * max(1.0, abs(b))

MUNNY_SITES = [0x2AC313, 0x2AC31F, 0x2AC32B]
def imm(g, a): return struct.unpack_from("<I", g.mem, a + 1)[0]
def disp_target(g, a): return a + 8 + struct.unpack_from("<i", g.mem, a + 4)[0]
READERS = {"exp": [0x2A4FB8, 0x2A50AB], "drop": [0x2ABB58, 0x2ABE50]}
def eff(g, kind):
    targets = {disp_target(g, a) for a in READERS[kind]}
    assert len(targets) == 1, targets
    return g.rf(targets.pop())
PATCHED_RANGES = [(0x2B2A7F,9),(0x2B2AAB,9),(0x2B2AD9,8),(0x2A4FB8,8),(0x2A50AB,8),(0x2ABB58,8),(0x2ABE50,8),(0x2AC313,5),(0x2AC31F,5),(0x2AC32B,5),(0x2AB4E1,8),(0x2AB539,8),(0x2AC145,8),(0x3EF6C8,12),(0x3EDE28,4)]
def code_vanilla(g): return all(g.mem[a:a+n] == IMAGE[a:a+n] for a,n in PATCHED_RANGES)

# 1. Vanilla config: no writes at all.
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute(1.2, 1.0, 1.5)
make_runtime(tree)
s = Script(g, tree); s.init(); s.frames(300)
check("vanilla: zero memory writes", len(g.writes) == 0, g.writes[:5])
log = (tree/"logs/kh1-runtime.log").read_text(encoding="utf-8")
check("vanilla: authorized", "Configuración activa" in log, log[-300:])

# 2. Dad Mode
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute(1.2, 1.0, 1.5)
make_runtime(tree, exp_multiplier=2, munny_multiplier=3, drop_multiplier=3, pickup_radius_multiplier=3)
s = Script(g, tree); s.init()
check("static patches applied before save load too", imm(g, 0x2AC313) == 3)
s.frames(10)
check("EXP readers see base*2", close(eff(g,"exp"), 2.4), eff(g,"exp"))
check("Drop readers see Lucky*3", close(eff(g,"drop"), 4.5), eff(g,"drop"))
check("game floats never written", g.rf(0x2D5CB00) == f32(1.2) and g.rf(0x2D60FA8) == 1.5)
check("Jackpot untouched", g.rf(0x2D60FA4) == 1.0)
check("munny orbs 3/15/60", [imm(g,a) for a in MUNNY_SITES] == [3,15,60], [imm(g,a) for a in MUNNY_SITES])
check("radius near 80^2*9", g.rf(0x3EF6C8) == 57600.0, g.rf(0x3EF6C8))
check("radius mid 120^2*9", g.rf(0x3EF6CC) == 129600.0)
check("radius tm2 400^2*9", g.rf(0x3EF6D0) == 1440000.0)
check("shared 200^2 const untouched", g.rf(0x3EDE28) == 40000.0)
check("tm1 loads redirected to private slot", all(disp_target(g,a) == 0x2F13FF0 for a in (0x2AB4E1,0x2AB539,0x2AC145)))
check("private slot 200^2*9", g.rf(0x2F13FF0) == 360000.0)
# stable: no rewrites each frame
n = len(g.writes); s.frames(120)
check("steady state: no repeated writes", len(g.writes) == n, len(g.writes) - n)
# game recomputes (equip change): new base 1.5 exp, lucky 2.0
g.recompute(1.2, 1.0, 1.5)
check("same-frame recompute: drop still x3", close(eff(g,"drop"), 4.5))
g.recompute(1.5, 1.0, 2.0); s.frames(1)
check("equipment change: EXP 1.5*2", close(eff(g,"exp"), 3.0), eff(g,"exp"))
check("equipment change: drop 2.0*3", close(eff(g,"drop"), 6.0), eff(g,"drop"))

# 3. Script reload (F1): new Lua state, same memory -> no double multiplication
s2 = Script(g, tree); s2.init(); s2.frames(10)
check("reload: EXP not doubled", close(eff(g,"exp"), 3.0), eff(g,"exp"))
check("reload: drop not doubled", close(eff(g,"drop"), 6.0), eff(g,"drop"))
check("reload: munny patch still 3/15/60", [imm(g,a) for a in MUNNY_SITES] == [3,15,60])
check("reload: radius not squared again", g.rf(0x3EF6C8) == 57600.0 and g.rf(0x2F13FF0) == 360000.0, g.rf(0x3EF6C8))

# 4. Live config change 3x -> 10x drop, 1.5 munny
make_runtime(tree, exp_multiplier=2, munny_multiplier=1.5, drop_multiplier=10, pickup_radius_multiplier=2)
s2.frames(121)
check("live change: drop 2.0*10", close(eff(g,"drop"), 20.0), eff(g,"drop"))
check("live change: munny 2/8/30", [imm(g,a) for a in MUNNY_SITES] == [2,8,30], [imm(g,a) for a in MUNNY_SITES])
check("live change: radius 2x", g.rf(0x3EF6C8) == 25600.0 and g.rf(0x2F13FF0) == 160000.0)

# 5. Back to vanilla -> every byte restored
make_runtime(tree)
s2.frames(121)
check("vanilla restore: readers point at game floats", eff(g,"exp") == 1.5 and eff(g,"drop") == 2.0)
check("vanilla restore: code/consts identical to EXE", code_vanilla(g))

# 6. Munny clamp
make_runtime(tree, munny_multiplier=10); s2.frames(121)
g.wi(0x2DFF77C, 99990 + 200); s2.frames(30)
check("munny clamped to 99999", g.ri(0x2DFF77C) == 99999, g.ri(0x2DFF77C))

# 7. Unknown build -> fail closed
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute()
g.mem[0x2A63DE] ^= 0xFF   # corrupt a code signature
make_runtime(tree, exp_multiplier=2, munny_multiplier=3, drop_multiplier=3, pickup_radius_multiplier=3)
s = Script(g, tree); s.init(); s.frames(300)
check("signature mismatch: zero writes", len(g.writes) == 0, g.writes[:5])
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute()
make_runtime(tree, build_hash="00"*32, exp_multiplier=2, munny_multiplier=3)
s = Script(g, tree); s.init(); s.frames(300)
check("hash mismatch: zero writes", len(g.writes) == 0)
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute()
make_runtime(tree, exp_multiplier=2)
s = Script(g, tree, game_id=0x1234); s.init(); s.frames(300)
check("GAME_ID mismatch: zero writes", len(g.writes) == 0)

# 7b. Migration from the first revision (tagged value written into the game float)
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save()
g.wf(0x2D60FA8, struct.unpack("<f", struct.pack("<I", 0x40C0005A))[0]); g.wf(0x2F13FE4, 2.0); g.wf(0x2D5CB00, 1.0)
make_runtime(tree, drop_multiplier=3)
s = Script(g, tree); s.init(); s.frames(3)
check("legacy tagged value restored to base", g.rf(0x2D60FA8) == 2.0 and close(eff(g,"drop"), 6.0), (g.rf(0x2D60FA8), eff(g,"drop")))

# 8. Foreign modification at a patch site -> that patch blocked, others fine
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute()
g.mem[0x2AC145 + 4] = 0x00  # someone else changed the tm1 load
make_runtime(tree, pickup_radius_multiplier=3, munny_multiplier=3)
s = Script(g, tree); s.init(); s.frames(5)
check("foreign bytes: radius feature rolled back to vanilla", g.rf(0x3EF6C8) == 6400.0 and disp_target(g,0x2AB4E1) == 0x3EDE28)
check("foreign bytes: munny still applied", imm(g,0x2AC313) == 3)

# 9. Title screen (no save): no data writes, only static code patches
tree = setup_tree(TMPDIR); g = Game(); g.recompute(0.0, 0.0, 0.0)
make_runtime(tree, exp_multiplier=2, drop_multiplier=3)
s = Script(g, tree); s.init(); s.frames(400)
check("title: readers not redirected without a save", eff(g,"exp") == 0.0 and eff(g,"drop") == 0.0)

# 10. Drop semantics simulation using the game's formula
import random
def enemy_drop_rate(chance, lucky):
    hits = 0
    for r in range(100):  # rand*100 truncated -> uniform 0..99
        if int(chance * lucky) > r: hits += 1
    return hits
for c, m, want in [(1,3,3),(4,3,12),(10,3,30),(25,3,75),(50,3,100),(100,3,100)]:
    check(f"drop formula {c}% x{m} -> {want}%", enemy_drop_rate(c, f32(1.0*m)) == want)

# 11. Non-dyadic multiplier keeps full precision
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute(1.0, 1.0, 1.0)
make_runtime(tree, drop_multiplier=2.4)
s = Script(g, tree); s.init(); s.frames(3)
check("10% x2.4 -> 24%", enemy_drop_rate(10, eff(g,"drop")) == 24, eff(g,"drop"))

# 12. Optional shop sales
T = 0x2D24798
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute()
make_runtime(tree, munny_multiplier=3)
s = Script(g, tree); s.init(); s.frames(60)
check("shop off: sell prices vanilla", all(g.sell(T,i) == 10 + i*5 for i in range(255)))
make_runtime(tree, munny_multiplier=3, multiply_shop_sales=True); s.frames(121)
check("shop on: sell x3", all(g.sell(T,i) == min(65535, (10 + i*5)*3) for i in range(255)), [g.sell(T,i) for i in range(3)])
check("shop on: buy prices untouched", all(g.buy(T,i) == 20 + i*10 for i in range(255)))
s2 = Script(g, tree); s2.init(); s2.frames(60)
check("shop reload: not x9", g.sell(T,1) == 45, g.sell(T,1))
make_runtime(tree, munny_multiplier=2, multiply_shop_sales=True); s2.frames(121)
check("shop live change: x2 from vanilla", g.sell(T,1) == 30, g.sell(T,1))
make_runtime(tree, munny_multiplier=2, multiply_shop_sales=False); s2.frames(121)
check("shop off again: exact vanilla restore", all(g.sell(T,i) == 10 + i*5 for i in range(255)))
T2 = 0x2D30000
g.set_item_table(T2); make_runtime(tree, munny_multiplier=3, multiply_shop_sales=True); s2.frames(121)
check("shop table reallocated: new snapshot x3", g.sell(T2,1) == 45, g.sell(T2,1))

# 13. Infinite MP uses the runtime maximum, not the save byte
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute()
g.wi(0x2D5CC54, 8); g.wi(0x2D5CC58, 15); g.mem[0x2DE9368] = 8
make_runtime(tree, infinite_mp=True)
s = Script(g, tree); s.init(); s.frames(2)
check("infinite MP refills to runtime max 15", g.ri(0x2D5CC54) == 15, g.ri(0x2D5CC54))
g.wi(0x2D5CC4C, 50); g.wi(0x2D5CC50, 102)
make_runtime(tree, infinite_mp=True, infinite_hp=True); s.frames(121)
check("infinite HP refills to runtime max 102", g.ri(0x2D5CC4C) == 102, g.ri(0x2D5CC4C))
g.wi(0x2D5CC4C, 0); s.frames(2)
check("infinite HP never revives from 0", g.ri(0x2D5CC4C) == 0)

# 14. Movement speed: all party slots (with a character record), never enemies
def slot_setup(g):
    mask = 0
    for i, rec in ((0, 0x2DE9364), (1, 0x2DE9364 + 0x74), (2, 0x2DE9364 + 0x74 * 2), (3, 0)):
        base = 0x2D5CC10 + i * 0x100
        g.wf(base + 8, 8.0)
        struct.pack_into("<Q", g.mem, base + 0xC8, (BASE + rec) if rec else 0)
        mask |= 1 << i
    g.wi(0x2D5CB04, mask)
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute(); slot_setup(g)
g.wf(0x2D5CB18, 16.0)   # dummy left at 16 by the first revision
make_runtime(tree, movement_speed_multiplier=1.5)
s = Script(g, tree); s.init(); s.frames(30)
check("speed: Sora 8 -> 12", g.rf(0x2D5CC18) == 12.0, g.rf(0x2D5CC18))
check("speed: Donald and Goofy 8 -> 12", g.rf(0x2D5CD18) == 12.0 and g.rf(0x2D5CE18) == 12.0, (g.rf(0x2D5CD18), g.rf(0x2D5CE18)))
check("speed: enemy slot untouched", g.rf(0x2D5CF18) == 8.0)
check("speed: dummy block cleaned back to 8", g.rf(0x2D5CB18) == 8.0, g.rf(0x2D5CB18))
s2 = Script(g, tree); s2.init(); make_runtime(tree, movement_speed_multiplier=1.0); s2.frames(150)
check("speed: after F1 reload, 1x restores 8 for all", all(g.rf(0x2D5CC18 + i * 0x100) == 8.0 for i in range(3)))
make_runtime(tree, movement_speed_multiplier=2.0); s2.frames(150)
g.wf(0x2D5CC18, 5.0); s2.frames(30)   # game sets a contextual speed (e.g. swimming)
check("speed: contextual game value left alone", g.rf(0x2D5CC18) == 5.0, g.rf(0x2D5CC18))
g.wf(0x2D5CC18, 8.0); s2.frames(30)
check("speed: reapplied when back to normal", g.rf(0x2D5CC18) == 16.0, g.rf(0x2D5CC18))

# 15. Glide follows movement speed via private floats (shared constants untouched)
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute()
make_runtime(tree, movement_speed_multiplier=2.0)
s = Script(g, tree); s.init(); s.frames(3)
def tgt9(a): return a + 9 + struct.unpack_from("<i", g.mem, a + 5)[0]
check("glide normal cap 8 -> 16", g.rf(tgt9(0x2B2AAB)) == 16.0, g.rf(tgt9(0x2B2AAB)))
check("glide superglide cap 16 -> 32", g.rf(tgt9(0x2B2A7F)) == 32.0)
check("glide accel 0.4 -> 0.8", abs(g.rf(disp_target(g, 0x2B2AD9)) - 0.8) < 1e-6)
check("shared constants untouched", g.rf(0x42F94C) == 8.0 and g.rf(0x42F964) == 16.0 and abs(g.rf(0x3EA1C8) - 0.4) < 1e-6)
make_runtime(tree, movement_speed_multiplier=1.0); s.frames(121)
check("glide restored at 1x", all(g.mem[a:a+n] == IMAGE[a:a+n] for a,n in [(0x2B2A7F,9),(0x2B2AAB,9),(0x2B2AD9,8)]))

# 16. Instant dialogue boxes
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute()
make_runtime(tree); s = Script(g, tree); s.init()
g.wf(0x22EC114, 0.6); s.frames(2)
check("faster text off: transition untouched", abs(g.rf(0x22EC114) - 0.6) < 1e-6)
make_runtime(tree, faster_text=True); s.frames(121); g.wf(0x22EC114, 0.6); s.frames(1)
check("faster text on: transition finished", g.rf(0x22EC114) == 0.0)
g.wf(0x233FBDC, 1.0); s.frames(5)
check("global timestep never written", g.rf(0x233FBDC) == 1.0)
g.wf(0x281249C, 0.0); g.wf(0x22EC114, 11.0); s.frames(1)   # HUD hidden during dialogue
check("faster text works while HUD is hidden", g.rf(0x22EC114) == 0.0, g.rf(0x22EC114))

# 17. Instant Gummi: native Warp Drive flag, independent of the HUD/save check
tree = setup_tree(TMPDIR); g = Game(); g.recompute()   # world map: no HUD, no loaded-save signals
make_runtime(tree); s = Script(g, tree); s.init(); s.frames(5)
check("gummi off: warp flag untouched", g.ri(0x2689878) == 0)
make_runtime(tree, instant_gummi=True); s.frames(121)
check("gummi on: warp flag set on the world map", g.ri(0x2689878) == 1)
g.wi(0x2689878, 0); s.frames(1)   # map re-opened, game recomputed 'no Warp gummi'
check("gummi on: re-applied after the game recomputes", g.ri(0x2689878) == 1)
g2 = Game(); g2.mem[0x1F375A] ^= 0xFF
t2 = setup_tree(TMPDIR); make_runtime(t2, instant_gummi=True); s2 = Script(g2, t2); s2.init(); s2.frames(5)
check("gummi: code signature mismatch -> no write", g2.ri(0x2689878) == 0)

# 18. Jump (Sora) via battle parameter table
def jw(g, off): return struct.unpack_from("<H", g.mem, 0x2D40000 + off)[0]
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute()
make_runtime(tree); s = Script(g, tree); s.init(); s.frames(60)
check("jump off: table untouched", jw(g,0x54) == 290 and jw(g,0x56) == 350)
make_runtime(tree, jump_multiplier=1.5); s.frames(150)
check("jump x1.5: table words 435/525", jw(g,0x54) == 435 and jw(g,0x56) == 525, (jw(g,0x54), jw(g,0x56)))
check("jump x1.5: live slot value updated", g.rf(0x2D5CC20) == 435.0, g.rf(0x2D5CC20))
s2 = Script(g, tree); s2.init(); s2.frames(60)
check("jump F1 reload: not compounded", jw(g,0x54) == 435, jw(g,0x54))
make_runtime(tree, jump_multiplier=1.0); s2.frames(150)
check("jump back to 1x: exact vanilla", jw(g,0x54) == 290 and jw(g,0x56) == 350 and g.rf(0x2D5CC20) == 290.0)
g3 = Game(); g3.set_loaded_save(); g3.wf(0x2D5CC20, 123.0)   # live jump does not match the table
t3 = setup_tree(TMPDIR); make_runtime(t3, jump_multiplier=2.0); s3 = Script(g3, t3); s3.init(); s3.frames(150)
check("jump sanity: mismatching table is never written", jw(g3,0x54) == 290)

# 19. Max HP / MP (Sora)
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute()
g.wi(0x2D5CC4C, 80); g.wi(0x2D5CC50, 100); g.wi(0x2D5CC54, 10); g.wi(0x2D5CC58, 20)
make_runtime(tree, player_hp_multiplier=2.0, mp_multiplier=1.5); s = Script(g, tree); s.init(); s.frames(30)
check("max HP x2 -> 200 (current kept at 80)", g.ri(0x2D5CC50) == 200 and g.ri(0x2D5CC4C) == 80, (g.ri(0x2D5CC50), g.ri(0x2D5CC4C)))
check("max MP x1.5 -> 30", g.ri(0x2D5CC58) == 30, g.ri(0x2D5CC58))
g.wi(0x2D5CC50, 110); s.frames(30)   # level up: game writes a new base
check("level up rebases: 110 x2 = 220", g.ri(0x2D5CC50) == 220, g.ri(0x2D5CC50))
s2 = Script(g, tree); s2.init(); s2.frames(30)
check("max HP F1 reload: not compounded", g.ri(0x2D5CC50) == 220, g.ri(0x2D5CC50))
g.wi(0x2D5CC4C, 210); make_runtime(tree); s2.frames(150)
check("back to 1x: max 110 and current clamped", g.ri(0x2D5CC50) == 110 and g.ri(0x2D5CC4C) == 110 and g.ri(0x2D5CC58) == 20, (g.ri(0x2D5CC50), g.ri(0x2D5CC4C)))

# 20. Enemy HP (all non-party slots, once per spawn)
tree = setup_tree(TMPDIR); g = Game(); g.set_loaded_save(); g.recompute(); slot_setup(g)
E = 0x2D5CF10   # slot 3 = enemy (no record)
g.wi(E + 0x3C, 50); g.wi(E + 0x40, 50)
g.wi(0x2D5CD10 + 0x3C, 60); g.wi(0x2D5CD10 + 0x40, 60)   # Donald (has a record)
make_runtime(tree); s = Script(g, tree); s.init(); s.frames(10)
check("enemy HP off: untouched", g.ri(E + 0x40) == 50)
make_runtime(tree, enemy_hp_multiplier=2.0); s.frames(121)
check("enemy HP x2 on spawn: 100/100", g.ri(E + 0x40) == 100 and g.ri(E + 0x3C) == 100, (g.ri(E + 0x3C), g.ri(E + 0x40)))
check("party member (Donald) untouched", g.ri(0x2D5CD10 + 0x40) == 60 and g.ri(0x2D5CD10 + 0x3C) == 60)
g.wi(E + 0x3C, 60); s.frames(5)
check("damaged enemy is not rescaled", g.ri(E + 0x40) == 100 and g.ri(E + 0x3C) == 60)
s2 = Script(g, tree); s2.init(); s2.frames(5)
check("enemy F1 reload: not rescaled", g.ri(E + 0x40) == 100)
make_runtime(tree); s2.frames(121); make_runtime(tree, enemy_hp_multiplier=2.0); s2.frames(121)
check("toggle 2x -> 1x -> 2x mid-fight: not rescaled", g.ri(E + 0x40) == 100, g.ri(E + 0x40))
g.wi(0x2D5CB04, 0b0111); s2.frames(2)                      # enemy despawns
g.wi(E + 0x3C, 40); g.wi(E + 0x40, 40); g.wi(0x2D5CB04, 0b1111); s2.frames(2)   # new spawn in that slot
check("new spawn in a reused slot is scaled", g.ri(E + 0x40) == 80, g.ri(E + 0x40))

print("\nFAILURES:", fails if fails else "none")
sys.exit(1 if fails else 0)
