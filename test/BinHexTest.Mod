MODULE BinHexTest;  (** BinHexTest.Compare a b: the files are the same *)
IMPORT Texts := Texts0, Oberon := Oberon0, Files, out;  (* the console modules: for both packages *)

PROCEDURE Compare*;
VAR S: Texts.Scanner; a, b: ARRAY 64 OF CHAR; fa, fb: Files.File; ra, rb: Files.Rider; ca, cb: CHAR; n: LONGINT; same: BOOLEAN;
BEGIN
  Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); COPY(S.s, a); Texts.Scan(S); COPY(S.s, b);
  fa := Files.Old(a); fb := Files.Old(b);
  IF (fa = NIL) OR (fb = NIL) THEN out.String("BinHexTest: missing file"); out.Ln; RETURN END;
  same := Files.Length(fa) = Files.Length(fb); Files.Set(ra, fa, 0); Files.Set(rb, fb, 0); n := 0;
  WHILE same & (n < Files.Length(fa)) DO Files.Read(ra, ca); Files.Read(rb, cb); same := ca = cb; INC(n) END;
  out.String("BinHexTest: "); out.Int(Files.Length(fa), 0); out.String(" bytes, ");
  IF same THEN out.String("same") ELSE out.String("different") END; out.Ln
END Compare;

END BinHexTest.
