# BinHex of ETH Oberon, for polpo

`BinHex.Decode file ...` decodes a BinHex 4.0 file (the `.hqx` files of the Macintosh, text
that survived mail and news) into `file`, its data fork:

    BinHex.Decode out name.hqx       the BinHex text in the file name.hqx
    BinHex.Decode out ^              the selected text
    BinHex.Decode out <text>         the text after the command

In the console: `binhex.Decode file name.hqx` (the result on the standard output).

    BinHex0.Mod   BinHex0.DecodeText(T, beg, F): from a text into a file; BinHex0.length is
                  the length of the data fork; works in the console and the desktop
    binhex.Mod    the console command
    BinHex.Mod    the desktop command (results in the log)

StuffIt archives (.sit) inside are not unpacked. The CRCs of the header, the data and the
resources are checked (Native Oberon did not); BinHex0.error says why a decoding failed.

From ETH Oberon (OLR), converted to plain text; the decoding moved to BinHex0. `test/`:
`BinHexTest.Mod`, the tests in the console: `BinHexTest.Encode` (a BinHex 4.0 encoder, which
made `sample.hqx` from `sample.bin`), `BinHexTest.Spoil` (a damaged copy, for the CRC) and
`BinHexTest.Compare`.

Install with portia: `portia.Install binhex` (the console command), `portia.Install
binhex-desktop` (the desktop command). The license is the one of ETH Oberon: `LICENSE`.
