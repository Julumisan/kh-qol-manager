"""Read-only PE byte-pattern scanner with Capstone context output."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "pydeps"))

import pefile  # type: ignore
from capstone import Cs, CS_ARCH_X86, CS_MODE_64  # type: ignore


def parse_pattern(text: str) -> list[int | None]:
    return [None if token in {"?", "??", "*"} else int(token, 16) for token in text.split()]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("exe", type=Path)
    parser.add_argument("pattern")
    parser.add_argument("--bytes", type=lambda value: int(value, 0), default=0x100)
    args = parser.parse_args()

    pe = pefile.PE(str(args.exe), fast_load=False)
    pattern = parse_pattern(args.pattern)
    md = Cs(CS_ARCH_X86, CS_MODE_64)
    hits = 0
    for section in pe.sections:
        if not section.IMAGE_SCN_MEM_EXECUTE:
            continue
        data = section.get_data()
        for index in range(0, len(data) - len(pattern) + 1):
            if all(expected is None or data[index + offset] == expected for offset, expected in enumerate(pattern)):
                rva = section.VirtualAddress + index
                print(f"\nHIT {hits + 1}: RVA 0x{rva:X}")
                code = data[index : index + args.bytes]
                for instruction in md.disasm(code, pe.OPTIONAL_HEADER.ImageBase + rva):
                    print(f"{instruction.address - pe.OPTIONAL_HEADER.ImageBase:08X}  {instruction.mnemonic:8} {instruction.op_str}")
                hits += 1
    print(f"\nTOTAL HITS: {hits}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
