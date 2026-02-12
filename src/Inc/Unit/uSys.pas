unit uSys;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Windows, SysUtils;

function SetDllDirectoryW(lpPathName: PWideChar): BOOL; stdcall; external 'kernel32.dll';
function GetDirFiles(const aDir, aMask: string): TStringList;
procedure SysPathAddd(const aPath: String);
function FileGetSize(const aFileName: string): Int64;
procedure FileAppendText(const aFile, aMsg: string);


implementation

procedure SysPathAddd(const aPath: String);
var
  Path: string;
begin
  SetDllDirectoryW('c:\Program Files\Medoc\Medoc\fb3\32');
end;

function FileGetSize(const aFileName: string): Int64;
var
  SR: TSearchRec;
begin
  if FindFirst(aFileName, faAnyFile, SR) = 0 then
  begin
    Result := SR.Size;
    FindClose(SR);
  end
  else
    Result := -1; // файл не знайдено
end;

function GetDirFiles(const aDir, aMask: string): TStringList;
var
  SR: TSearchRec;
  FilePath: string;
  Masks: TStringList;
  I: Integer;
begin
  Result := TStringList.Create;
  Masks := TStringList.Create;
  try
    Masks.StrictDelimiter := True;
    Masks.Delimiter := ';';
    Masks.DelimitedText := aMask;

    for I := 0 to Masks.Count - 1 do
    begin
      if FindFirst(aDir + PathDelim + Masks[I], faAnyFile, SR) = 0 then
      begin
        repeat
          if (SR.Attr and faDirectory) = 0 then
          begin
            FilePath := aDir + PathDelim + SR.Name;
            Result.Add(FilePath);
          end;
        until FindNext(SR) <> 0;
        FindClose(SR);
      end;
    end;

  finally
    Masks.Free();
  end;
end;

procedure FileAppendText(const aFile, aMsg: string);
var
  HFile: TextFile;
begin
  AssignFile(HFile, aFile);
  if FileExists(aFile) then
    Append(HFile)
  else
    Rewrite(HFile);

  try
    Writeln(HFile, aMsg);
  finally
    CloseFile(HFile);
  end;
end;

end.

