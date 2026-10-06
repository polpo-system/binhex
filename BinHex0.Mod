(* ETH Oberon, Copyright 1990-2003 Computer Systems Institute, ETH Zurich, CH-8092 Zurich.
Refer to the license.txt file provided with this distribution. *)

MODULE BinHex0;	(** portable *) (* ejz,  *)
(** BinHex decodeing, sit not yet supported *)
(* polpo: DecodeText of BinHex, for the desktop (BinHex) and the console (binhex); the CRCs are
   checked (they were not), error says why a decoding failed *)

	IMPORT SYSTEM, Files, Texts := Texts0;

	VAR
		encTable: ARRAY 64 OF CHAR;
		decTable: ARRAY 128 OF INTEGER;
		length*: LONGINT;  (** the length of the data fork of the last DecodeText *)
		error*: ARRAY 64 OF CHAR;  (** why the last DecodeText failed, "" if it did not *)

	(* polpo: the CRC-16 (CCITT, polynomial 1021H) of the next n bytes of r and of the two bytes of
	   the CRC that follow them: 0 when it is right *)
	PROCEDURE CRC(VAR r: Files.Rider; n: LONGINT): LONGINT;
		VAR crc: LONGINT; ch: CHAR; k: INTEGER;
	BEGIN
		crc := 0; INC(n, 2);
		WHILE (n > 0) & ~r.eof DO
			Files.Read(r, ch);
			crc := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, crc) / SYSTEM.VAL(SET, LONG(ORD(ch)) * 256));
			k := 0;
			WHILE k < 8 DO
				crc := crc * 2;
				IF crc >= 10000H THEN crc := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, crc - 10000H) / SYSTEM.VAL(SET, LONG(1021H))) END;
				INC(k)
			END;
			DEC(n)
		END;
		IF n > 0 THEN crc := -1 END;  (* the file ends too early *)
		RETURN crc
	END CRC;

	PROCEDURE DecodeText*(T: Texts.Text; beg: LONGINT; F: Files.File): BOOLEAN;
		VAR
			Rt: Texts.Reader;
			Rf, R: Files.Rider;
			S: Texts.Scanner;
			codes: ARRAY 4 OF INTEGER;
			dlen, rlen, hlen: LONGINT;
			i: INTEGER;
			ok, end: BOOLEAN;
			ch, last: CHAR;
	BEGIN
		error := "";
(* search BinHex *)
		Texts.OpenScanner(S, T, beg); Texts.Scan(S);
		WHILE ~S.eot & ~((S.class = Texts.Name) & (S.s = "BinHex")) DO
			Texts.Scan(S)
		END;
		IF S.eot THEN
			error := "no BinHex text"; RETURN FALSE
		END;
		Texts.OpenReader(Rt, T, Texts.Pos(S)); Texts.Read(Rt, ch);
		WHILE ~Rt.eot & (ch # ":") DO
			Texts.Read(Rt, ch)
		END;
(* decode ascii to bin *)
		Texts.Read(Rt, ch);
		ok := TRUE; end := FALSE;
		Files.Set(Rf, Files.New(""), 0);
		REPEAT
			i := 0;
			WHILE ~Rt.eot & ok & (i < 4) DO
				WHILE ~Rt.eot & (ch <= " ")  DO
					Texts.Read(Rt, ch)
				END;
				codes[i] := decTable[ORD(ch)];
				ok := codes[i] >= 0; INC(i);
				IF ok THEN
					Texts.Read(Rt, ch)
				END
			END;
			IF i > 0 THEN
				IF ok THEN
					Files.Write(Rf, CHR(ASH(codes[0], 2)+ASH(codes[1], -4)));
					Files.Write(Rf, CHR(ASH(codes[1], 4)+ASH(codes[2], -2)));
					Files.Write(Rf, CHR(ASH(codes[2], 6)+codes[3]))
				ELSIF ch = ":" THEN
					ok := TRUE; end := TRUE; DEC(i);
					IF i = 2 THEN
						Files.Write(Rf, CHR(ASH(codes[0], 2)+ASH(codes[1], -4)))
					ELSIF i = 3 THEN
						Files.Write(Rf, CHR(ASH(codes[0], 2)+ASH(codes[1], -4)));
						Files.Write(Rf, CHR(ASH(codes[1], 4)+ASH(codes[2], -2)))
					ELSIF i # 0 THEN
						ok := FALSE
					END
				END
			ELSE
				end := TRUE; ok := ch = ":"
			END
		UNTIL Rt.eot OR end;
		IF ~ok OR ~end THEN
			error := "bad or incomplete BinHex text"; RETURN FALSE
		END;
(* decode rle *)
		Files.Set(R, Files.New(""), 0);
		Files.Set(Rf, Files.Base(Rf), 0);
		last := 0X; Files.Read(Rf, ch);
		WHILE ~Rf.eof DO
			IF ch = CHR(090H) THEN
				Files.Read(Rf, ch);
				IF ch = 0X THEN
					last := CHR(090H); Files.Write(R, CHR(0090H))
				ELSE
					i := ORD(ch)-1;
					WHILE i > 0 DO
						Files.Write(R, last); DEC(i)
					END
				END
			ELSE
				last := ch; Files.Write(R, ch);
			END;
			Files.Read(Rf, ch)
		END;
(* decode hqx *)
		Files.Set(Rf, Files.Base(R), 0);
		Files.Read(Rf, ch); last := ch;
		Files.Set(Rf, Files.Base(R), 1+ORD(ch)+1+4+4+2);
		Files.Read(Rf, ch); dlen := ORD(ch);
		Files.Read(Rf, ch); dlen := 256*dlen+ORD(ch);
		Files.Read(Rf, ch); dlen := 256*dlen+ORD(ch);
		Files.Read(Rf, ch); dlen := 256*dlen+ORD(ch);
		Files.Read(Rf, ch); rlen := ORD(ch);
		Files.Read(Rf, ch); rlen := 256*rlen+ORD(ch);
		Files.Read(Rf, ch); rlen := 256*rlen+ORD(ch);
		Files.Read(Rf, ch); rlen := 256*rlen+ORD(ch);
		(* polpo: the CRCs of the header, the data fork and the resource fork *)
		hlen := 1+ORD(last)+1+4+4+2+4+4;
		Files.Set(Rf, Files.Base(R), 0);
		IF CRC(Rf, hlen) # 0 THEN error := "wrong CRC of the header"; RETURN FALSE END;
		IF CRC(Rf, dlen) # 0 THEN error := "wrong CRC of the data"; RETURN FALSE END;
		IF CRC(Rf, rlen) # 0 THEN error := "wrong CRC of the resources"; RETURN FALSE END;
		Files.Set(Rf, Files.Base(R), hlen+2);
		length := dlen;
		Files.Set(R, F, 0); Files.Read(Rf, ch);
		WHILE ~Rf.eof & (dlen > 0) DO
			Files.Write(R, ch); Files.Read(Rf, ch); DEC(dlen)
		END;
		IF dlen # 0 THEN error := "the data is incomplete"; RETURN FALSE END;
		RETURN TRUE
	END DecodeText;



	PROCEDURE InitTables();
		VAR i: INTEGER;
	BEGIN
		FOR i := 0 TO 127 DO
			decTable[i] := -1
		END;
		FOR i := 0 TO 63 DO
			encTable[i] := 0X
		END;
		FOR i := 0 TO 12 DO (* ! .. - *)
			encTable[i] := CHR(i+33)
		END;
		FOR i := 13 TO 19 DO (* 0 .. 6 *)
			encTable[i] := CHR(i-13+48)
		END;
		FOR i := 20 TO 21 DO (* 8 .. 9 *)
			encTable[i] := CHR(i-20+56)
		END;
		FOR i := 22 TO 36 DO (* @ .. N *)
			encTable[i] := CHR(i-22+64)
		END;
		FOR i := 37 TO 43 DO (* P .. V *)
			encTable[i] := CHR(i-37+80)
		END;
		FOR i := 44 TO 47 DO (* X .. [ *)
			encTable[i] := CHR(i-44+88)
		END;
		FOR i := 48 TO 54 DO (* ' .. f *)
			encTable[i] := CHR(i-48+96)
		END;
		FOR i := 55 TO 60 DO (* h .. m *)
			encTable[i] := CHR(i-55+104)
		END;
		FOR i := 61 TO 63 DO (* p  .. r *)
			encTable[i] := CHR(i-61+112)
		END;
		FOR i := 0 TO 63 DO
			decTable[ORD(encTable[i])] := i
		END
	END InitTables;

BEGIN
	InitTables(); length := 0; error := ""
END BinHex0.

System.Free BinHex BinHex0 ~
