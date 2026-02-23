unit uProtect;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, crc;

const
  cSkipTailLen = 128;

type
  TProtect = class
  private
    fFile: String;
    fBodyCRC, fTailCRC: Cardinal;
    Timer1: TTimer;
    procedure OnTimer(Sender: TObject);
  public
    constructor Create(const aFile: String);
    function CompareRnd(): Boolean;
    function GetFileBodyCRC(SkipLastBytes: Integer = 0): Cardinal;
    function ReadFileTailAsCardinal(): Cardinal;
    procedure WriteFileTailAsCardinal(aVal: Cardinal);
    procedure TimerRunRnd(aMod: boolean; aInterval: Integer = 10000 );
  end;

var
  Protect: TProtect;

implementation

constructor TProtect.Create(const aFile: String);
begin
  fFile := aFile;
  fBodyCRC := 0;
  fTailCRC := 0;

  Timer1 := TTimer.Create(Nil);
  Timer1.Enabled := False;
end;

procedure TProtect.TimerRunRnd(aMod: boolean; aInterval: Integer = 10000 );
begin
  Timer1.Enabled := aMod;
  Timer1.Interval := aInterval + Random(aInterval);
  Timer1.OnTimer := @OnTimer;
end;

procedure TProtect.OnTimer(Sender: TObject);
begin
  Timer1.Enabled := False;

  fBodyCRC := GetFileBodyCRC(cSkipTailLen);
  fTailCRC := ReadFileTailAsCardinal();
end;


function TProtect.GetFileBodyCRC(SkipLastBytes: Integer = 0): Cardinal;
const
  BUF_SIZE = 64 * 1024;
var
  FS: TFileStream;
  Buffer: array[0..BUF_SIZE - 1] of Byte;
  ToRead, Readed: Integer;
  Remaining: Int64;
begin
  Result := 0;
  if (not FileExists(fFile)) then
    Exit;

  FS := TFileStream.Create(fFile, fmOpenRead or fmShareDenyWrite);
  try
    if (FS.Size < SkipLastBytes) then
      Exit;

    Remaining := FS.Size - SkipLastBytes;
    Result := crc32(0, nil, 0);

    while (Remaining > 0) do
    begin
      ToRead := BUF_SIZE;
      if (Remaining < ToRead) then
        ToRead := Remaining;

      Readed := FS.Read(Buffer, ToRead);
      if (Readed <= 0) then
        Break;

      Result := crc32(Result, @Buffer[0], Readed);
      Dec(Remaining, Readed);
    end;
  finally
    FS.Free();
  end;
end;

function TProtect.ReadFileTailAsCardinal(): Cardinal;
var
  FS: TFileStream;
begin
  Result := 0;
  if not FileExists(fFile) then
    Exit;

  FS := TFileStream.Create(fFile, fmOpenRead or fmShareDenyWrite);
  try
    FS.Position := FS.Size - SizeOf(Cardinal);
    FS.ReadBuffer(Result, SizeOf(Cardinal));
  finally
    FS.Free();
  end;
end;

procedure TProtect.WriteFileTailAsCardinal(aVal: Cardinal);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(fFile, fmOpenReadWrite or fmShareDenyWrite);
  try
    FS.Position := FS.Size;              // перейти в кінець
    FS.WriteBuffer(aVal, SizeOf(aVal)); // записати 4 байти
  finally
    FS.Free;
  end;
end;

function TProtect.CompareRnd(): Boolean;
begin
  if (fBodyCRC = fTailCRC) then
    Result := True
  else
    Result := Random(4) = 0;
end;

end.

