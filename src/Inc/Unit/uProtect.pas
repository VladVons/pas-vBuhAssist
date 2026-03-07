// Created: 2026.02.24
// Author: Vladimir Vons <VladVons@gmail.com>

unit uProtect;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Windows, crc,
  uSys;

const
  cTailSign = 1971;

type
  TAnyMethod = procedure of object;

  TTail = packed record
    Sign: integer;
    BlockLen: Cardinal;
    CheckSum: Cardinal;
    ModDate: TDateTime;
    Pretend: array[0..32] of char;
  end;

  TProtect = class
  private
    fFile: string;
    fTimingStart: Cardinal;
  protected
    fTail: TTail;
    fProtected: boolean;
  public
    fTimingCnt: Cardinal;
    constructor Create(const aFile: string);
    function CompareRnd(): boolean;
    function CalculateFileTail(aLen: integer): TTail;
    function ReadFileTail(): TTail;
    procedure WriteFileTail(aTail: TTail);
    procedure ReadCRC();
    procedure TimingStart();
    function TimingCheck(aDif: integer = 100): boolean;
    function IsBreakpoint(aMethod: Pointer): Boolean;
    function IsBreakpoint2(aMethod: TAnyMethod): Boolean;
    function IsDebugger1(): boolean;
    function IsDebugger2(): boolean;
    function IsDeveloper(): boolean;
  end;

var
  Protect: TProtect;

implementation

constructor TProtect.Create(const aFile: string);
begin
  fFile := aFile;
  fProtected := True;
  fTimingCnt := 0;
  fTail := Default(TTail);

  Randomize();
end;

function TProtect.IsDebugger1(): boolean;
begin
 Result := IsDebuggerPresent();
end;

function TProtect.IsDebugger2(): Boolean;
begin
  Result := False;
  try
    asm
      int3;
    end;
  except
    Result := False;
    Exit();
  end;

  Result := True;
end;

//usage: ProtectTimer.IsBreakpoint(TMethod(@ProtectTimer.CompareRnd).Code)
function TProtect.IsBreakpoint(aMethod: Pointer): Boolean;
begin
  Result := PByte(aMethod)^ = $CC;
end;

function TProtect.IsBreakpoint2(aMethod: TAnyMethod): Boolean;
begin
  Result := PByte(TMethod(aMethod).Code)^ = $CC;
end;

function TProtect.IsDeveloper(): boolean;
var
  Str: string;
begin
  Str := GetAppName() + '.lpr';
  Result := FileExists(Str);
end;

function TProtect.CalculateFileTail(aLen: integer): TTail;
const
  BUF_SIZE = 64 * 1024;
var
  FS: TFileStream;
  Buffer: array[0..BUF_SIZE - 1] of byte;
  ToRead, Readed: integer;
  Remaining: Int64;
begin
  Result := Default(TTail);
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
    while (Remaining > 0) do
    begin
      ToRead := BUF_SIZE;
      if (Remaining < ToRead) then
        ToRead := integer(Remaining);

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
  Result := Default(TTail);
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

function TProtect.CompareRnd(): boolean;
begin
  if (fProtected) then
    Result := True
  else
    Result := Random(4) = 0;
end;

procedure TProtect.TimingStart();
begin
  fTimingStart := GetTickCount();
end;

function TProtect.TimingCheck(aDif: integer = 100): boolean;
var
  Dif: integer;
begin
  Dif := GetTickCount() - fTimingStart;
  Result := Dif > aDif;
  if (Result) then
  begin
    Inc(fTimingCnt);
    Result := Random(2) = 0;
  end;

  fTimingStart := GetTickCount();
end;

end.

