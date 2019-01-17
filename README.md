# dcrc32

## Example

```pascal
uses
  dcrc32;

...

var
  S: AnsiString;
  Crc: Cardinal;

...

  Crc := GetCrc32Hash(@S[1], Length(S));
```

## Iterative CRC-32 calculation

```pascal
var
  Crc: Cardinal;

...
  
  // Initialize checksum
  Crc := Crc32Init;

  for {Each portion of data (Data, Size)} do
    Crc := Crc32Update(Crc, Data, Size);

  // Get final checksum
  Crc := Crc32Final(Crc);
```

## Generating CRC-32 lookup table

It is possible to use [dcrc32_table](dcrc32_table.pas) unit to build any CRC-32 checksum calculator.

First, generate lookup-table with `GenerateCrc32Table` for specified polynomial (in reversed form):

```pascal
var
  CRC32C_TABLE: array[0..255] of Cardinal;

...

  // Generate table for CRC-32C (Castagnoli)
  // Reversed polynomial for CRC-32C is $82F63B78
  GenerateCrc32Table($82F63B78, @CRC32C_TABLE[0]);
```

Second, use `AccumulateCrc32` for each portion of data to compute checksum. For example, here is how to compute CRC-32C:

```pascal
function GetCrc32CHash(P: Pointer; Size: SizeUInt): Cardinal; inline;
begin
  Result := AccumulateCrc32(
    $FFFFFFFF, // InitValue for CRC-32C is $FFFFFFFF
    @CRC32C_TABLE[0],
    P,
    Size) xor $FFFFFFFF; // XorOut for CRC-32C is $FFFFFFFF
end;
```
