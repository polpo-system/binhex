#!/usr/bin/env python3
# mkhqx.py in out.hqx: a BinHex 4.0 file of in (data fork only), for the test of BinHex.Decode
import binascii, struct, sys, os
ALPHA = b'!"#$%&\'()*+,-012345689@ABCDEFGHIJKLMNPQRSTUVXYZ[`abcdefhijklmpqr'
def crc(b): return binascii.crc_hqx(b + b'\0\0', 0)
def rle(b):
    out = bytearray(); i = 0
    while i < len(b):
        c = b[i]; n = 1
        while i + n < len(b) and b[i + n] == c and n < 255: n += 1
        lit = bytes([c, 0]) if c == 0x90 else bytes([c])
        if n >= 3: out += lit + bytes([0x90, n])
        else: out += lit * n
        i += n
    return bytes(out)
def enc6(b):
    bits = 0; nb = 0; out = bytearray()
    for c in b:
        bits = bits << 8 | c; nb += 8
        while nb >= 6: nb -= 6; out.append(ALPHA[bits >> nb & 63])
    if nb: out.append(ALPHA[bits << (6 - nb) & 63])
    return bytes(out)
src, dst = sys.argv[1], sys.argv[2]
data = open(src, 'rb').read(); name = os.path.basename(src).encode()
hdr = bytes([len(name)]) + name + b'\0' + b'TEXT' + b'ttxt' + b'\0\0' + struct.pack('>II', len(data), 0)
body = hdr + struct.pack('>H', crc(hdr)) + data + struct.pack('>H', crc(data)) + struct.pack('>H', crc(b''))
e = enc6(rle(body))
lines = [e[i:i + 64] for i in range(0, len(e), 64)]
open(dst, 'wb').write(b'(This file must be converted with BinHex 4.0)\n\n:' + b'\n'.join(lines) + b':\n')
