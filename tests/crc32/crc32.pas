{$MODE FPC}
{$MODESWITCH OUT}
{$MODESWITCH RESULT}
uses
  dcrc32,
  dcrc32_table;

var
  CRC32C_TABLE: array[0 .. 255] of Cardinal;

procedure Assert(B: Boolean; Msg: PAnsiChar);
begin
  if not B then
    Writeln(Msg);
end;

function DumpLineToStr(P: PByte; Size: LongInt): AnsiString;
var
  I: LongInt;
begin
  Result := '';
  for I := 0 to 15 do begin
    if Size > I then begin
      Result := Result + HexStr(P[I], 2);
    end else
      Result := Result + '  ';
    if I mod 4 = 3 then
      Result := Result + '  ';
  end;
  Result := Result + '| ';
  for I := 0 to 15 do begin
    if Size <= I then
      break;
    if (P[I] >= 32) and (P[I] < 127) then begin
      Result := Result + Char(P[I])
    end else
      Result := Result + '?';
  end;
end;

function DumpToStr(P: Pointer; Size: LongInt): AnsiString;
begin
  Result := '';
  while Size > 0 do begin
    if Size >= 16 then begin
      Result := Result + DumpLineToStr(P, 16) + LineEnding;
      Size := Size - 16;
      Inc(P, 16);
    end else begin
      Result := Result + DumpLineToStr(P, Size) + LineEnding;
      Break;
    end;
  end;
end;

procedure Dump(P: Pointer; Size: LongInt);
begin
  Write(DumpToStr(P, Size));
end;

procedure CheckCrc32(S: PAnsiChar; Expected, ExpectedCrc32C: Cardinal);
var
  Crc: Cardinal;
  I: LongInt;
begin
  Write('CRC32("');
  if StrLen(S) > 16 then begin
    for I := 0 to 15 do
      Write(S[I]);
    Write('...');
  end else
    Write(S);
  Write('") = ');

  Crc := GetCrc32Hash(S, StrLen(S));
  Write(HexStr(Crc, 8));

  if Crc <> Expected then begin
    Write(' (failed! expected: ', HexStr(Expected, 8), ')');
  end;

  Crc := Crc32Init;
  for I := 0 to StrLen(S) - 1 do
    Crc := Crc32Update(Crc, @S[I], 1);
  Crc := Crc32Final(Crc);
  if Crc <> Expected then begin
    Write(' (iteration failed! expected: ', HexStr(Crc, 8), ')');
  end;

  Write(', CRC32C = ');
  Crc := AccumulateCrc32($FFFFFFFF, @CRC32C_TABLE, S, StrLen(S)) xor $FFFFFFFF;
  Write(HexStr(Crc, 8));
  if Crc <> ExpectedCrc32C then
    Write(' (failed! expected: ', HexStr(ExpectedCrc32C, 8), ')');

  Writeln;
end;

const
  CPU_STRING = {$IF Defined(CPUARM)} 'arm'
               {$ELSEIF Defined(CPUAVR)} 'avr'
               {$ELSEIF Defined(CPUAMD64) or Defined(CPUX86_64)} 'intel-64'
               {$ELSEIF Defined(CPU68) or Defined(CPU86K) or Defined(CPUM68K)} 'Motorola 680x0'
               {$ELSEIF Defined(CPUPOWERPC) or Defined(CPUPOWERPC32) or Defined(CPUPOWERPC64)} 'PowerPC'
               {$ELSEIF Defined(CPU386) or Defined(CPUi386)} 'i386'
               {$ELSE} 'uknown arch'
               {$ENDIF};
  ENDIAN_STRING = {$IF Defined(ENDIAN_LITTLE)}{$IF Defined(ENDIAN_BIG)}'little/big endian'{$ELSE}'little endian'{$ENDIF}
                  {$ELSE}{$IF Defined(ENDIAN_BIG)}'big endian'{$ELSE}'unknown endian'{$ENDIF}{$ENDIF};
  BITS_STRING = {$IF Defined(CPU64)}'64'{$ELSEIF Defined(CPU32)}'32'{$ELSEIF Defined(CPU16)}'16'{$ELSE}'?'{$ENDIF};
  OS_STRING = {$IF Defined(AMIGA)} 'amiga'
              {$ELSEIF Defined(ATARI)} 'Atari'
              {$ELSEIF Defined(GO32V2) or Defined(DPMI)} 'MS-DOS go32v2'
              {$ELSEIF Defined(MACOS)} 'Classic Macintosh'
              {$ELSEIF Defined(MSDOS)} 'MS-DOS'
              {$ELSEIF Defined(OS2)} 'OS2'
              {$ELSEIF Defined(EMX)} 'EMX'
              {$ELSEIF Defined(PALMOS)} 'PalmOS'
              {$ELSEIF Defined(BEOS)} 'BeOS'
              {$ELSEIF Defined(DARWIN)} 'MacOS or iOS'
              {$ELSEIF Defined(FREEBSD)} 'FreeBSD'
              {$ELSEIF Defined(NETBSD)} 'NetBSD'
              {$ELSEIF Defined(SUNOS)} 'SunOS'
              {$ELSEIF Defined(SOLARIS)} 'Solaris'
              {$ELSEIF Defined(QNX)} 'QNX RTP'
              {$ELSEIF Defined(LINUX)} 'Linux'
              {$ELSEIF Defined(UNIX)} 'Unix'
              {$ELSEIF Defined(WIN32)} '32-bit Windows'
              {$ELSEIF Defined(WIN64)} '64-bit Windows'
              {$ELSEIF Defined(WINCE)} 'Windows CE or Windows Mobile'
              {$ELSEIF Defined(WINDOWS)} 'Windows'
              {$ELSE} 'Unknown OS'
              {$ENDIF};
  PLATFORM_STRING = CPU_STRING + ' ' + BITS_STRING + '-bits (' + ENDIAN_STRING + '), ' + OS_STRING;

var
  Table: array[0..255] of Cardinal;
  I, J: LongInt;

begin
  Write(stderr, PLATFORM_STRING);
  Writeln(stderr);

  GenerateCrc32Table($EDB88320, @Table[0]);
  for I := 0 to 5 * 4 - 1 {256 div 4 - 1} do begin
    for J := 0 to 7 do begin
      Write(HexStr(Table[I * 4 + J], 8), ' ');
    end;
    Writeln;
  end;

  GenerateCrc32Table($82F63B78, @CRC32C_TABLE[0]);

  Writeln;
  CheckCrc32('', 0, 0);
  CheckCrc32('hello', $3610A686, $9A71BB4C);
  CheckCrc32('123456789', $CBF43926, $E3069283);
  CheckCrc32('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', $98B2C5BD, $95DC2E4B);
end.
