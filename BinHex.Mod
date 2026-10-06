(* ETH Oberon, Copyright 1990-2003 Computer Systems Institute, ETH Zurich, CH-8092 Zurich.
Refer to the license.txt file provided with this distribution. *)

MODULE BinHex;	(** portable *) (* ejz,  *)
(** BinHex decodeing, sit not yet supported *)
(* polpo: the desktop command; the decoding is in BinHex0, binhex has it for the console *)

	IMPORT Files, Texts, Oberon, BinHex0;

	VAR
		W: Texts.Writer;

	(** BinHex.Decode file (name.hqx | ^ | @ | text): decode the BinHex text into file *)
	PROCEDURE Decode*;
		VAR
			S: Texts.Scanner;
			F: Files.File;
			T: Texts.Text;
			beg, end, time: LONGINT;
	BEGIN
		Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
		Texts.Scan(S);
		IF S.class IN {Texts.Name, Texts.String} THEN
			Texts.WriteString(W, S.s); F := Files.New(S.s);
			Texts.Scan(S);
			IF (S.class = Texts.Char) & ((S.c = "@") OR (S.c = "^")) THEN
				T := NIL; time := -1;
				Oberon.GetSelection(T, beg, end, time);
				IF T = NIL THEN
					RETURN
				END
			ELSIF S.class IN {Texts.Name, Texts.String} THEN
				NEW(T); Texts.Open(T, S.s);
				beg := 0
			ELSE
				beg := Texts.Pos(S);
				T := Oberon.Par.text
			END;
			IF BinHex0.DecodeText(T, beg, F) THEN
				Files.Register(F);
				Texts.Write(W, " "); Texts.WriteInt(W, BinHex0.length, 0); Texts.WriteString(W, " done")
			ELSE
				Texts.WriteString(W, " failed")
			END;
			Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
		END
	END Decode;

BEGIN
	Texts.OpenWriter(W)
END BinHex.
