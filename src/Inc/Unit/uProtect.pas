// Created: 2026.02.24
// Author: Vladimir Vons <VladVons@gmail.com>

unit uProtect;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, crc,
  uSys;

const
  cTailSign = 1971;

type
  TTail = packed record
    Sign: Integer;
    BlockLen: Cardinal;
    CheckSum: Cardinal;
    ModDate: TDateTime;
    Pretend: array[0..32] of Char;
  end;

  TProtect = class
  private
    fFile: String;
  protected
    fTail: TTail;
    fProtected: Boolean;
  public
    constructor Create(const aFile: String);
    function CompareRnd(): Boolean;
    function CalculateFileTail(aLen: Integer): TTail;
    function ReadFileTail(): TTail;
    procedure WriteFileTail(aTail: TTail);
    procedure ReadCRC();
  end;

var
  Protect: TProtect;

implementation

constructor TProtect.Create(const aFile: String);
begin
  fFile := aFile;
  fProtected := True;
  FillChar(fTail, SizeOf(TTail), 0);
end;

function TProtect.CalculateFileTail(aLen: Integer): TTail;
const
  BUF_SIZE = 64 * 1024;
var
  FS: TFileStream;
  Buffer: array[0..BUF_SIZE - 1] of Byte;
  ToRead, Readed: Integer;
  Remaining: Int64;
begin
  FillChar(Result, SizeOf(TTail), 0);
  if not FileExists(fFile) then
     Exit;

  FS := TFileStream.Create(fFile, fmOpenRead or fmShareDenyWrite);
  try
    Result.ModDate := FileGetModDate(fFile);

    if (aLen = 0) then
      aLen := FS.Size;
    Result.BlockLen := aLen;

    FS.Position := 0;
    Result.CheckSum := crc32(0, nil, 0);

    Remaining := aLen;
    while Remaining > 0 do
    begin
      ToRead := BUF_SIZE;
      if Remaining < ToRead then
        ToRead := Integer(Remaining);

      Readed := FS.Read(Buffer, ToRead);
      if Readed <= 0 then
         Break;

      Result.CheckSum := crc32(Result.CheckSum, @Buffer[0], Readed);
      Dec(Remaining, Readed);
    end;
  finally
    FS.Free();
  end;
end;

function TProtect.ReadFileTail(): TTail;
var
  FS: TFileStream;
begin
  FillChar(Result, SizeOf(TTail), 0);
  if not FileExists(fFile) then
    Exit;

  FS := TFileStream.Create(fFile, fmOpenRead or fmShareDenyWrite);
  try
    FS.Position := FS.Size - SizeOf(TTail);
    FS.ReadBuffer(Result, SizeOf(TTail));
  finally
    FS.Free();
  end;
end;

procedure TProtect.WriteFileTail(aTail: TTail);
var
  FS: TFileStream;
begin
  aTail.Sign := cTailSign;
  StrPLCopy(@aTail.Pretend[0], 'HEAP_LOADER_$', SizeOf(aTail.Pretend) - 1);

  FS := TFileStream.Create(fFile, fmOpenReadWrite or fmShareDenyWrite);
  try
    FS.Position := FS.Size;              // перейти в кінець
    FS.WriteBuffer(aTail, SizeOf(TTail));
  finally
    FS.Free();
  end;
end;

procedure TProtect.ReadCRC();
var
  TailRec, TailNow: TTail;
begin
  TailRec := ReadFileTail();
  if (TailRec.Sign = cTailSign) then
  begin
    TailNow := CalculateFileTail(TailRec.BlockLen);
    fProtected := TailRec.CheckSum = TailNow.CheckSum;
  end;
end;

function TProtect.CompareRnd(): Boolean;
begin
  if (fProtected) then
    Result := True
  else
    Result := Random(4) = 0;
end;

end.

