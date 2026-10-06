MODULE BinHexTest;  (** the tests of binhex, in the console *)

(* BinHexTest.Encode file name.hqx     a BinHex 4.0 text of file (data fork only, type TEXT)
   BinHexTest.Spoil a b pos             b is a with the character at pos changed
   BinHexTest.Compare a b               are the files a and b the same *)

IMPORT SYSTEM, Files, texts, out;

VAR alphabet: ARRAY 65 OF CHAR;  (* the 64 characters of BinHex 4.0 *)

PROCEDURE Args(VAR a, b: ARRAY OF CHAR): BOOLEAN;
VAR A: texts.Reader;
BEGIN texts.OpenArgs(A); RETURN texts.Arg(A, a) & texts.Arg(A, b)
END Args;

(* the CRC-16 of BinHex (CCITT, polynomial 1021H) after the byte ch *)
PROCEDURE CRC(crc: LONGINT; ch: CHAR): LONGINT;
VAR k: INTEGER;
BEGIN
  crc := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, crc) / SYSTEM.VAL(SET, LONG(ORD(ch)) * 256)); k := 0;
  WHILE k < 8 DO
    crc := crc * 2;
    IF crc >= 10000H THEN crc := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, crc - 10000H) / SYSTEM.VAL(SET, LONG(1021H))) END;
    INC(k)
  END;
  RETURN crc
END CRC;

PROCEDURE Encode*;
VAR in, name: ARRAY 64 OF CHAR; f, b, h: Files.File; r, w: Files.Rider; ch, last: CHAR;
  crc, n, len, bits, nb, col, i: LONGINT; run: INTEGER;

  PROCEDURE Byte(c: CHAR);  (* to the body, counted into crc *)
  BEGIN Files.Write(w, c); crc := CRC(crc, c)
  END Byte;

  PROCEDURE Long(x: LONGINT);
  BEGIN Byte(CHR(x DIV 1000000H MOD 100H)); Byte(CHR(x DIV 10000H MOD 100H)); Byte(CHR(x DIV 100H MOD 100H)); Byte(CHR(x MOD 100H))
  END Long;

  PROCEDURE EndCRC;  (* the CRC so far, then a new one *)
  VAR c: LONGINT;
  BEGIN c := crc; Files.Write(w, CHR(c DIV 100H)); Files.Write(w, CHR(c MOD 100H)); crc := 0
  END EndCRC;

  PROCEDURE Put(c: CHAR);  (* six bits at a time to the text, lines of 64 *)
  BEGIN
    bits := bits * 256 + ORD(c); INC(nb, 8);
    WHILE nb >= 6 DO
      DEC(nb, 6); Files.Write(w, alphabet[bits DIV ASH(1, nb) MOD 64]); bits := bits MOD ASH(1, nb);
      INC(col); IF col = 64 THEN Files.Write(w, 0AX); col := 0 END
    END
  END Put;

  PROCEDURE Str(s: ARRAY OF CHAR);
  BEGIN i := 0; WHILE s[i] # 0X DO Files.Write(w, s[i]); INC(i) END
  END Str;

BEGIN
  IF ~Args(in, name) THEN out.String("usage: BinHexTest.Encode file name.hqx"); out.Ln; RETURN END;
  f := Files.Old(in); IF f = NIL THEN out.String("BinHexTest: no "); out.String(in); out.Ln; RETURN END;
  len := Files.Length(f);
  (* the body: header, data fork, resource fork (empty), each with its CRC *)
  b := Files.New(""); Files.Set(w, b, 0); crc := 0;
  n := 0; WHILE in[n] # 0X DO INC(n) END;
  Byte(CHR(n)); i := 0; WHILE i < n DO Byte(in[i]); INC(i) END; Byte(0X);
  Byte("T"); Byte("E"); Byte("X"); Byte("T"); Byte("t"); Byte("t"); Byte("x"); Byte("t"); Byte(0X); Byte(0X);
  Long(len); Long(0); EndCRC;
  Files.Set(r, f, 0); Files.Read(r, ch); WHILE ~r.eof DO Byte(ch); Files.Read(r, ch) END; EndCRC;
  EndCRC;
  (* run length encoding (90X n, a literal 90X as 90X 0) and the six bit text *)
  h := Files.New(name); Files.Set(w, h, 0); Str("(This file must be converted with BinHex 4.0)"); Files.Write(w, 0AX); Files.Write(w, 0AX);
  Files.Write(w, ":"); bits := 0; nb := 0; col := 1;
  Files.Set(r, b, 0); Files.Read(r, ch);
  WHILE ~r.eof DO
    last := ch; run := 1; Files.Read(r, ch);
    WHILE ~r.eof & (ch = last) & (run < 255) DO INC(run); Files.Read(r, ch) END;
    Put(last); IF last = 90X THEN Put(0X) END;
    IF run >= 3 THEN Put(90X); Put(CHR(run))
    ELSIF run = 2 THEN Put(last); IF last = 90X THEN Put(0X) END
    END
  END;
  IF nb > 0 THEN Files.Write(w, alphabet[bits * ASH(1, 6 - nb) MOD 64]) END;
  Files.Write(w, ":"); Files.Write(w, 0AX); Files.Register(h);
  out.String("BinHexTest: "); out.String(name); out.String(" from "); out.Int(len, 0); out.String(" bytes"); out.Ln
END Encode;

PROCEDURE Spoil*;
VAR a, b: ARRAY 64 OF CHAR; A: texts.Reader; p: ARRAY 16 OF CHAR; pos, i: LONGINT; fa, fb: Files.File; ra, rb: Files.Rider; ch: CHAR;
BEGIN
  texts.OpenArgs(A);
  IF ~texts.Arg(A, a) OR ~texts.Arg(A, b) OR ~texts.Arg(A, p) THEN out.String("usage: BinHexTest.Spoil a b pos"); out.Ln; RETURN END;
  pos := 0; i := 0; WHILE p[i] # 0X DO pos := pos * 10 + ORD(p[i]) - ORD("0"); INC(i) END;
  fa := Files.Old(a); fb := Files.New(b); Files.Set(ra, fa, 0); Files.Set(rb, fb, 0); i := 0;
  Files.Read(ra, ch);
  WHILE ~ra.eof DO
    IF i = pos THEN IF ch = "A" THEN ch := "B" ELSE ch := "A" END END;  (* another character of the alphabet *)
    Files.Write(rb, ch); Files.Read(ra, ch); INC(i)
  END;
  Files.Register(fb); out.String("BinHexTest: "); out.String(b); out.String(" spoiled at "); out.Int(pos, 0); out.Ln
END Spoil;

PROCEDURE Compare*;
VAR a, b: ARRAY 64 OF CHAR; fa, fb: Files.File; ra, rb: Files.Rider; ca, cb: CHAR; n: LONGINT; same: BOOLEAN;
BEGIN
  IF ~Args(a, b) THEN out.String("usage: BinHexTest.Compare a b"); out.Ln; RETURN END;
  fa := Files.Old(a); fb := Files.Old(b);
  IF (fa = NIL) OR (fb = NIL) THEN out.String("BinHexTest: missing file"); out.Ln; RETURN END;
  same := Files.Length(fa) = Files.Length(fb); Files.Set(ra, fa, 0); Files.Set(rb, fb, 0); n := 0;
  WHILE same & (n < Files.Length(fa)) DO Files.Read(ra, ca); Files.Read(rb, cb); same := ca = cb; INC(n) END;
  out.String("BinHexTest: "); out.Int(Files.Length(fa), 0); out.String(" bytes, ");
  IF same THEN out.String("same") ELSE out.String("different") END; out.Ln
END Compare;

PROCEDURE Init;
VAR s: ARRAY 64 OF CHAR; i, j: INTEGER;
BEGIN  (* both quotes are in it: in three parts *)
  alphabet := '!"#$%&'; i := 6; alphabet[i] := "'"; INC(i);
  s := "()*+,-012345689@ABCDEFGHIJKLMNPQRSTUVXYZ[`abcdefhijklmpqr";
  j := 0; WHILE s[j] # 0X DO alphabet[i] := s[j]; INC(i); INC(j) END;
  alphabet[i] := 0X
END Init;

BEGIN
  Init
END BinHexTest.
