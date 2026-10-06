# BinHex of ETH Oberon, for polpo

`BinHex.Decode file ...` decodes a BinHex 4.0 file (the `.hqx` files of the Macintosh, text
that survived mail and news) into `file`, its data fork:

    BinHex.Decode out name.hqx       the BinHex text in the file name.hqx
    BinHex.Decode out ^              the selected text
    BinHex.Decode out <text>         the text after the command

`BinHex.DecodeText(T, beg, F)` decodes from a text into a file. It is a desktop command (the
result goes to the log). StuffIt archives (.sit) inside are not unpacked.

From ETH Oberon (OLR), converted to plain text. `test/`: `mkhqx.py`, a BinHex 4.0 encoder that
made `sample.hqx` from `sample.bin`, and `BinHexTest.Compare a b`, the test of the package
(needs the desktop).

Install with portia: `portia.Install binhex`. The license is the one of ETH Oberon: `LICENSE`.
