MODULE binhex;  (** BinHex decoding for the console of polpo *)

(* binhex.Decode file name.hqx   decodes the BinHex 4.0 text in name.hqx into file (its data
   fork). BinHex.Decode is the desktop command. *)

IMPORT Files, Texts0, Texts, BinHex0, Out;

PROCEDURE Decode*;
VAR A: Texts.Reader; name, src: ARRAY 256 OF CHAR; F: Files.File; T: Texts0.Text;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, name) OR ~Texts.Arg(A, src) THEN Out.String("usage: binhex.Decode file name.hqx"); Out.Ln; RETURN END;
  IF Files.Old(src) = NIL THEN Out.String("binhex: cannot read "); Out.String(src); Out.Ln; RETURN END;
  NEW(T); Texts0.Open(T, src); F := Files.New(name);
  IF BinHex0.DecodeText(T, 0, F) THEN
    Files.Register(F); Out.String("binhex: "); Out.String(name); Out.String(", "); Out.Int(BinHex0.length, 0); Out.String(" bytes")
  ELSE Out.String("binhex: "); Out.String(src); Out.String(": "); Out.String(BinHex0.error)
  END;
  Out.Ln
END Decode;

END binhex.
