unit uProtect;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, crc;

const
  cSkipTailLen = 32;

type
  TProtect = class
  private
    fFile: String;
  protected
    fBodyCRC, fTailCRC: Cardinal;
    fProtected: Boolean;
  public
    constructor Create(const aFile: String);
    function CompareRnd(): Boolean;
    function GetFileBodyCRC(aSkipLastBytes: Integer = 0): Cardinal;
    function ReadFileTailAsCardinal(): Cardinal;
    procedure WriteFileTailAsCardinal(aVal: Cardinal);
    procedure ReadCRC();
  end;

var
  Protect: TProtect;

implementation

constructor TProtect.Create(const aFile: String);
begin
  fFile := aFile;
  fBodyCRC := 0;
  fTailCRC := 0;
end;

function TProtect.GetFileBodyCRC(aSkipLastBytes: Integer = 0): Cardinal;
const
  BUF_SIZE = 64 * 1024;
var
  FS: TFileStream;
  Buffer: array[0..BUF_SIZE - 1] of Byte;
  ToRead, Readed: Integer;
  Remaining: Int64;
begin
  Result := 0;
  if not FileExists(fFile) then
     Exit;

  FS := TFileStream.Create(fFile, fmOpenRead or fmShareDenyWrite);
  try
    if FS.Size <= Int64(aSkipLastBytes) then
      Exit;

    FS.Position := 0;
    Remaining := FS.Size - aSkipLastBytes;
    Result := crc32(0, nil, 0);

    while Remaining > 0 do
    begin
      ToRead := BUF_SIZE;
      if Remaining < ToRead then
        ToRead := Integer(Remaining);

      Readed := FS.Read(Buffer, ToRead);
      if Readed <= 0 then
         Break;

      Result := crc32(Result, @Buffer[0], Readed);
      Dec(Remaining, Readed);
    end;
  finally
    FS.Free;
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
    FS.WriteBuffer(aVal, SizeOf(Cardinal));
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

procedure TProtect.ReadCRC();
begin
  fBodyCRC := GetFileBodyCRC(cSkipTailLen);
  fTailCRC := ReadFileTailAsCardinal();
  fProtected := fBodyCRC = fTailCRC;
end;

end.

