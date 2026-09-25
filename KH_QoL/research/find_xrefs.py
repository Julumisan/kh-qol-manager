"""Read-only x64 PE helper: list RIP-relative and immediate references to RVAs."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "pydeps"))

import pefile  # type: ignore  # noqa: E402
from capstone import Cs, CS_ARCH_X86, CS_MODE_64  # type: ignore  # noqa: E402
from capstone.x86 import X86_OP_IMM, X86_OP_MEM, X86_REG_RIP  # type: ignore  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("exe", type=Path)
    parser.add_argument("rvas", nargs="+", type=lambda value: int(value, 0))
    parser.add_argument("--context", type=int, default=6)
    args = parser.parse_args()

    pe = pefile.PE(str(args.exe), fast_load=False)
    image_base = pe.OPTIONAL_HEADER.ImageBase
    wanted = set(args.rvas)
    md = Cs(CS_ARCH_X86, CS_MODE_64)
    md.detail = True
    # PE executable sections may contain alignment bytes or small embedded data
    # islands.  Without skipdata Capstone stops at the first undecodable byte and
    # silently misses every valid reference that follows it.
    md.skipdata = True

    instructions = []
    hits = []
    for section in pe.sections:
        if not section.IMAGE_SCN_MEM_EXECUTE:
            continue
        base = image_base + section.VirtualAddress
        for insn in md.disasm(section.get_data(), base):
            index = len(instructions)
            instructions.append(insn)
            # Capstone represents bytes skipped by skipdata as pseudo
            # instructions without operand detail.
            if insn.id == 0:
                continue
            for operand in insn.operands:
                target = None
                if operand.type == X86_OP_MEM and operand.mem.base == X86_REG_RIP:
                    target = insn.address + insn.size + operand.mem.disp - image_base
                elif operand.type == X86_OP_IMM:
                    value = operand.imm
                    if image_base <= value < image_base + pe.OPTIONAL_HEADER.SizeOfImage:
                        target = value - image_base
                if target in wanted:
                    hits.append((index, target))

    print(f"image_base=0x{image_base:X} image_size=0x{pe.OPTIONAL_HEADER.SizeOfImage:X}")
    for index, target in hits:
        print(f"\nTARGET RVA 0x{target:X}")
        first = max(0, index - args.context)
        last = min(len(instructions), index + args.context + 1)
        for i in range(first, last):
            insn = instructions[i]
            marker = ">" if i == index else " "
            print(f"{marker} {insn.address - image_base:08X}  {insn.mnemonic:8} {insn.op_str}")

    missing = wanted - {target for _, target in hits}
    if missing:
        print("\nNO DIRECT XREF:", ", ".join(f"0x{x:X}" for x in sorted(missing)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
