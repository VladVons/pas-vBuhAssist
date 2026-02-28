// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSys;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Windows, SysUtils, StrUtils, FileInfo, Process;

function AddDllDirectory(aDir: PWideChar): THandle; stdcall; external 'kernel32.dll';
function SetDllDirectoryW(lpPathName: PWideChar): BOOL; stdcall; external 'kernel32.dll';
function SetDefaultDllDirectories(aDirFlags: DWORD): BOOL; stdcall; external 'kernel32.dll';

function ExecProcess(const aFile: string; aParam: TStrings = Nil): TProcess;
function GetMonthNameUa(aMonthNum: integer): string;
function GetAppProgramData(): string;
function GetAppName(): string;
function GetDirFiles(const aDir, aMask: string): TStringList;
procedure AddDirDll(const aPath: string);
function FileGetSize(const aFileName: string): Int64;
function FileGetModDate(const aFile: string): TDateTime;
procedure FileAppendText(const aFile, aMsg: string);
procedure StrToFile(const aStr: AnsiString; aFile: string);
function StrFromFile(const aFile: string): AnsiString;
function GetAppVer(aBuildOnly: boolean = False): string;
function IsRealApp(aCond: boolean = True): boolean;
function ExpandEnvVar(const aStr: string): string;


implementation

function ExecProcess(const aFile: string; aParam: TStrings = Nil): TProcess;
var
  Dir: string;
begin
  if (not FileExists(aFile)) then
    raise Exception.Create('Не знайдено ' + aFile);

  Dir := ExtractFilePath(aFile);

  Result := TProcess.Create(nil);
  Result.Executable := aFile;
  Result.CurrentDirectory := Dir;
  Result.Options := [poUsePipes, poWaitOnExit];
  Result.ShowWindow := swoHide;
  if (Assigned(aParam)) then
    Result.Parameters := aParam;
  Result.Execute();
end;

procedure AddDirDll(const aPath: string);
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
  end else
    Result := -1; // файл не знайдено
end;

function FileGetModDate(const aFile: string): TDateTime;
var
  SR: TSearchRec;
begin
  if FindFirst(AFile, faAnyFile, SR) = 0 then
  begin
    Result := FileDateToDateTime(SR.Time);
    FindClose(SR);
  end else
    Result := 0;
end;

function GetDirFiles(const aDir, aMask: string): TStringList;
var
  SR: TSearchRec;
  FilePath: string;
  Masks: TStringList;
  I: integer;
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
      SetLength(Result, Size div SizeOf(char));
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

function GetAppName(): string;
begin
  Result := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
end;

function GetAppProgramData(): string;
begin
  Result := GetEnvironmentVariable('ProgramData') + PathDelim + GetAppName();
end;

function GetAppVer(aBuildOnly: boolean = false): string;
var
  Info: TVersionInfo;
begin
  Info := TVersionInfo.Create();
  try
    // Завантажуємо інформацію з поточного виконуваного файлу
    Info.Load(HINSTANCE);
    if (aBuildOnly) then
       Result := IntToStr(Info.FixedInfo.FileVersion[3])
    else begin
      Result := Format('%d.%d.%d.%d', [
        Info.FixedInfo.FileVersion[0], // Major
        Info.FixedInfo.FileVersion[1], // Minor
        Info.FixedInfo.FileVersion[2], // Revision
        Info.FixedInfo.FileVersion[3]  // Build
      ]);
    end;
  finally
    Info.Free();
  end;
end;

function GetAppVerBuild(): string;
begin
end;

function GetMonthNameUa(aMonthNum: integer): string;
const
  Months: array[1..12] of string = (
    'Січень','Лютий','Березень','Квітень', 'Травень','Червень',
    'Липень','Серпень', 'Вересень','Жовтень','Листопад','Грудень'
  );
begin
  if (aMonthNum < 1) or (aMonthNum > 12) then
    Exit('');

  Result := Months[aMonthNum];
end;

function IsRealApp(aCond: boolean = True): boolean;
var
  Str: string;
begin
  Str := GetAppName() + '.lpr';
  Result := (not FileExists(Str)) and aCond;
end;

function ExpandEnvVar(const aStr: string): string;
var
  p1, p2: integer;
  Env, Macros: string;
begin
  Result := aStr;

  p1 := Pos('%', Result);
  while p1 > 0 do
  begin
    p2 := PosEx('%', Result, p1 + 1);
    if (p2 = 0) then
      Break;

    Macros := Copy(Result, p1 + 1, p2 - p1 - 1);
    Env := GetEnvironmentVariable(Macros);
    Result := StuffString(Result, p1, p2 - p1 + 1, Env);

    p1 := Pos('%', Result);
  end;
end;

initialization
  //SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);

end.

