MODULE binhex;  (** BinHex decoding for the console of polpo *)

(* binhex.Decode file name.hqx   decodes the BinHex 4.0 text in name.hqx into file (its data
   fork). BinHex.Decode is the desktop command. *)

IMPORT Files, Texts := Texts0, texts, BinHex0, out;

PROCEDURE Decode*;
VAR A: texts.Reader; name, src: ARRAY 256 OF CHAR; F: Files.File; T: Texts.Text;
BEGIN
  texts.OpenArgs(A);
  IF ~texts.Arg(A, name) OR ~texts.Arg(A, src) THEN out.String("usage: binhex.Decode file name.hqx"); out.Ln; RETURN END;
  IF Files.Old(src) = NIL THEN out.String("binhex: cannot read "); out.String(src); out.Ln; RETURN END;
  NEW(T); Texts.Open(T, src); F := Files.New(name);
  IF BinHex0.DecodeText(T, 0, F) THEN
    Files.Register(F); out.String("binhex: "); out.String(name); out.String(", "); out.Int(BinHex0.length, 0); out.String(" bytes")
  ELSE out.String("binhex: "); out.String(src); out.String(": "); out.String(BinHex0.error)
  END;
  out.Ln
END Decode;

END binhex.
