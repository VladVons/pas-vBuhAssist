// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSys;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Windows, SysUtils, FileInfo;

function AddDllDirectory(aDir: PWideChar): THandle; stdcall; external 'kernel32.dll';
function SetDllDirectoryW(lpPathName: PWideChar): BOOL; stdcall; external 'kernel32.dll';
function SetDefaultDllDirectories(aDirFlags: DWORD): BOOL; stdcall; external 'kernel32.dll';

function GetAppProgramData(): String;
function GetAppName(): String;
function GetDirFiles(const aDir, aMask: string): TStringList;
function GetAppFile(const aFile: String): String;
procedure AddDirDll(const aPath: String);
function FileGetSize(const aFileName: string): Int64;
procedure FileAppendText(const aFile, aMsg: string);
procedure StrToFile(const aStr: AnsiString; aFile: string);
function StrFromFile(const aFile: string): AnsiString;
function GetAppVer(): string;


implementation

procedure AddDirDll(const aPath: String);
var
  ws: WideString;
begin
  if (not DirectoryExists(aPath)) then
    raise Exception.Create('Directory not found: ' + aPath);

  ws := UTF8Decode(aPath);
  SetDllDirectoryW(PWideChar(ws));
  //AddDllDirectory(PWideChar(ws));
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
  Result := TStringList.Create();

  Masks := TStringList.Create;
  Masks.StrictDelimiter := True;
  Masks.Delimiter := ';';
  Masks.DelimitedText := aMask;

  try
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

procedure StrToFile(const aStr: AnsiString; aFile: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(aFile, fmCreate);
  try
    FS.WriteBuffer(Pointer(aStr)^, Length(aStr));
  finally
    FS.Free();
  end;
end;

function StrFromFile(const aFile: string): AnsiString;
var
  FS: TFileStream;
  Size: integer;
begin
  Result := '';
  FS := TFileStream.Create(aFile, fmOpenRead or fmShareDenyNone);
  try
    Size := FS.Size;
    if (Size > 0) then
    begin
      SetLength(Result, Size div SizeOf(Char));
      FS.ReadBuffer(Pointer(Result)^, Size);
    end;
  finally
    FS.Free();
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

function GetAppName(): String;
begin
  Result := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
end;

function GetAppProgramData(): String;
begin
  Result := GetEnvironmentVariable('ProgramData') + PathDelim + GetAppName();
end;


function GetAppFile(const aFile: String): String;
var
  DirApp: String;
begin
  DirApp := GetAppConfigDir(False);
  if (not DirectoryExists(DirApp)) then
     ForceDirectories(DirApp);

  Result := ConcatPaths([DirApp, aFile]);
end;

function GetAppVer(): string;
var
  Info: TVersionInfo;
begin
  Info := TVersionInfo.Create();
  try
    // Завантажуємо інформацію з поточного виконуваного файлу
    Info.Load(HINSTANCE);
    Result := Format('%d.%d.%d.%d', [
      Info.FixedInfo.FileVersion[0], // Major
      Info.FixedInfo.FileVersion[1], // Minor
      Info.FixedInfo.FileVersion[2], // Revision
      Info.FixedInfo.FileVersion[3]  // Build
    ]);
  finally
    Info.Free();
  end;
end;

initialization
  //SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);

end.

