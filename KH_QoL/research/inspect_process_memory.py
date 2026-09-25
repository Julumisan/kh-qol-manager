"""Read-only helper for validating LuaBackend RVAs against a running game.

It never requests write access. Addresses without --absolute are interpreted as
RVAs relative to the executable module, matching LuaBackend's normal API.
"""

from __future__ import annotations

import argparse
import ctypes
import struct
from ctypes import wintypes

PROCESS_QUERY_INFORMATION = 0x0400
PROCESS_VM_READ = 0x0010

kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
psapi = ctypes.WinDLL("psapi", use_last_error=True)

kernel32.OpenProcess.argtypes = (wintypes.DWORD, wintypes.BOOL, wintypes.DWORD)
kernel32.OpenProcess.restype = wintypes.HANDLE
kernel32.ReadProcessMemory.argtypes = (
    wintypes.HANDLE,
    wintypes.LPCVOID,
    wintypes.LPVOID,
    ctypes.c_size_t,
    ctypes.POINTER(ctypes.c_size_t),
)
kernel32.ReadProcessMemory.restype = wintypes.BOOL
kernel32.CloseHandle.argtypes = (wintypes.HANDLE,)
psapi.EnumProcessModules.argtypes = (
    wintypes.HANDLE,
    ctypes.POINTER(wintypes.HMODULE),
    wintypes.DWORD,
    ctypes.POINTER(wintypes.DWORD),
)
psapi.EnumProcessModules.restype = wintypes.BOOL


def read(handle: int, address: int, size: int) -> bytes:
    buffer = ctypes.create_string_buffer(size)
    done = ctypes.c_size_t()
    if not kernel32.ReadProcessMemory(handle, address, buffer, size, ctypes.byref(done)):
        raise OSError(ctypes.get_last_error(), f"ReadProcessMemory 0x{address:X}")
    return buffer.raw[: done.value]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("pid", type=int)
    parser.add_argument("addresses", nargs="+", type=lambda value: int(value, 0))
    parser.add_argument("--absolute", action="store_true")
    parser.add_argument("--size", type=lambda value: int(value, 0), default=32)
    parser.add_argument("--deref", action="store_true")
    args = parser.parse_args()

    handle = kernel32.OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, False, args.pid)
    if not handle:
        raise OSError(ctypes.get_last_error(), "OpenProcess")
    try:
        module = wintypes.HMODULE()
        needed = wintypes.DWORD()
        if not psapi.EnumProcessModules(handle, ctypes.byref(module), ctypes.sizeof(module), ctypes.byref(needed)):
            raise OSError(ctypes.get_last_error(), "EnumProcessModules")
        base = int(ctypes.cast(module, ctypes.c_void_p).value or 0)
        print(f"pid={args.pid} module_base=0x{base:X}")
        for value in args.addresses:
            address = value if args.absolute else base + value
            data = read(handle, address, args.size)
            suffix = ""
            if args.deref and len(data) >= 8:
                pointer = struct.unpack_from("<Q", data)[0]
                suffix = f" pointer=0x{pointer:X}"
                if pointer:
                    try:
                        pointed = read(handle, pointer, args.size)
                        suffix += f" pointed={pointed.hex(' ')}"
                    except OSError as error:
                        suffix += f" pointed_error={error}"
            print(f"0x{value:X} -> 0x{address:X}: {data.hex(' ')}{suffix}")
    finally:
        kernel32.CloseHandle(handle)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
