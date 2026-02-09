unit uSys;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Windows, SysUtils;

function SetDllDirectoryW(lpPathName: PWideChar): BOOL; stdcall; external 'kernel32.dll';
function GetDirFiles(const aDir, aMask: string): TStringList;
procedure SysPathAddd(const aPath: String);
function GetFileSize(const aFileName: string): Int64;


implementation

procedure SysPathAddd(const aPath: String);
var
  Path: string;
begin
  SetDllDirectoryW('c:\Program Files\Medoc\Medoc\fb3\32');
end;

function GetFileSize(const aFileName: string): Int64;
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
begin
  Result := TStringList.Create();
  if FindFirst(IncludeTrailingPathDelimiter(aDir) + aMask, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory) = 0 then
        FilePath := aDir + PathDelim + SR.Name;
        Result.Add(FilePath);
    until (FindNext(SR) <> 0);
    FindClose(SR);
  end;
end;

end.

