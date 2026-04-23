// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uSys;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Windows, SHFolder, SysUtils, StrUtils, FileInfo, Process, fpjson,
  uHelper;

function AddDllDirectory(aDir: PWideChar): THandle; stdcall; external 'kernel32.dll';
function SetDllDirectoryW(lpPathName: PWideChar): BOOL; stdcall; external 'kernel32.dll';
function SetDefaultDllDirectories(aDirFlags: DWORD): BOOL; stdcall; external 'kernel32.dll';

function ExecProcess(const aFile: string; aParam: TStrings = Nil; aOptions: TProcessOptions = []): TProcess;
function GetMonthNameUa(aMonthNum: integer): string;
function GetAppProgramData(): string;
function GetAppName(): string;
function GetAppDir(): string;
function GetAppVer(aBuildOnly: boolean = False): string;
function GetExeVer(const aFile: string): string;
function GetDirFiles(const aDir, aMask: string): TStringList;
function GetDesktopDir(): string;
procedure AddDirDll(const aPath: string);
function FileGetSize(const aFileName: string): Int64;
function FileGetModDate(const aFile: string): TDateTime;
function FileLoadJson(const aFile: string): TJSONData;
procedure FileAppendText(const aFile, aMsg: string);
function StrFromFile(const aFile: string): string;
function ExpandEnvVar(const aStr: string): string;
procedure WaitProcess(aPID: DWORD);

implementation

function FileLoadJson(const aFile: string): TJSONData;
var
  SL: TStringList;
begin
  SL := TStringList.Create();
  try
    SL.LoadFromFile(aFile);
    Result := GetJSON(SL.Text);
  finally
    SL.Free();
  end;
end;

function ExecProcess(const aFile: string; aParam: TStrings; aOptions: TProcessOptions): TProcess;
var
  Dir: string;
begin
  if (not aFile.FileExists()) then
    raise Exception.Create('Не знайдено ' + aFile);

  Result := TProcess.Create(nil);
  Result.Executable := aFile;

  Dir := ExtractFilePath(aFile);
  if (not Dir.IsEmpty()) then
     Result.CurrentDirectory := Dir;

  Result.ShowWindow := swoHide;

  if (aOptions = []) then
     aOptions :=  [poWaitOnExit];
  Result.Options := aOptions;
  //Result.Options := [poUsePipes] //uncatched exception in slave;

  if (aParam <> nil) then
    Result.Parameters := aParam;

  Result.Execute();
end;

procedure WaitProcess(aPID: DWORD);
var
  hProc: THandle;
begin
  hProc := OpenProcess(SYNCHRONIZE, False, aPID);
  if (hProc <> 0) then
  begin
    WaitForSingleObject(hProc, INFINITE); // чекаємо завершення
    CloseHandle(hProc);
  end;
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
  if (FindFirst(aFileName, faAnyFile, SR) = 0) then
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
  if (FindFirst(AFile, faAnyFile, SR) = 0) then
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

  Masks := TStringList.Create();
  Masks.StrictDelimiter := True;
  Masks.Delimiter := ';';
  Masks.DelimitedText := aMask;

  try
    for I := 0 to Masks.Count - 1 do
    begin
      if (FindFirst(ConcatPaths([aDir, Masks[I]]), faAnyFile, SR) = 0) then
      begin
        repeat
          if (SR.Attr and faDirectory) = 0 then
          begin
            FilePath := ConcatPaths([aDir, SR.Name]);
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
  if (aFile.FileExists()) then
    Append(HFile)
  else
    Rewrite(HFile);

  try
    Writeln(HFile, aMsg);
  finally
    CloseFile(HFile);
  end;
end;

function StrFromFile(const aFile: string): string;
var
  FStream: TFileStream;
  Size: integer;
begin
  Result := '';
  FStream := TFileStream.Create(aFile, fmOpenRead or fmShareDenyNone);
  try
    Size := FStream.Size;
    if (Size > 0) then
    begin
      SetLength(Result, Size div SizeOf(char));
      FStream.ReadBuffer(Pointer(Result)^, Size);
    end;
  finally
    FStream.Free();
  end;
end;


function GetAppName(): string;
begin
  Result := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
end;

function GetAppDir(): string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

function GetAppProgramData(): string;
begin
  Result := ConcatPaths([GetEnvironmentVariable('ProgramData'), GetAppName()]);
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
      Result := Format('%d.%d.%d', [
        //Info.FixedInfo.FileVersion[0], // Major
        Info.FixedInfo.FileVersion[1], // Minor
        Info.FixedInfo.FileVersion[2], // Revision
        Info.FixedInfo.FileVersion[3]  // Build
      ]);
    end;
  finally
    Info.Free();
  end;
end;

function GetDesktopDir(): string;
var
  Path: array[0..MAX_PATH] of Char;
begin
  if SHGetFolderPath(0, CSIDL_DESKTOPDIRECTORY, 0, 0, @Path[0]) = S_OK then
    Result := Path
  else
    Result := '';
end;

function GetExeVer(const aFile: string): string;
var
  InfoSize, Wnd: DWORD;
  VerBuf: Pointer;
  VerSize: DWORD;
  VerValue: PVSFixedFileInfo;
begin
  Result := '';
  VerValue := Nil;
  VerSize := 0;
  Wnd := 0;

  InfoSize := GetFileVersionInfoSize(PChar(aFile), Wnd);
  if (InfoSize = 0) then
     Exit();

  GetMem(VerBuf, InfoSize);
  try
    if (GetFileVersionInfo(PChar(aFile), Wnd, InfoSize, VerBuf)) then
      if (VerQueryValue(VerBuf, '\', Pointer(VerValue), VerSize)) then
        Result := Format('%d.%d.%d.%d',
          [HiWord(VerValue^.dwFileVersionMS),
           LoWord(VerValue^.dwFileVersionMS),
           HiWord(VerValue^.dwFileVersionLS),
           LoWord(VerValue^.dwFileVersionLS)]);
  finally
    FreeMem(VerBuf);
  end;
end;

function GetMonthNameUa(aMonthNum: integer): string;
const
  Months: array[1..12] of string = (
    'Січень','Лютий','Березень',
    'Квітень', 'Травень','Червень',
    'Липень','Серпень', 'Вересень',
    'Жовтень','Листопад','Грудень'
  );
begin
  if (aMonthNum < 1) or (aMonthNum > 12) then
    Exit('');

  Result := Months[aMonthNum];
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

end.

