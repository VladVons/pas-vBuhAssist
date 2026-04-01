program vAppUpd;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, CustApp, opensslsockets, URIParser, fpjson,  jsonparser, Process, fphttpclient,
  uSys, uHttp, uArchive, uVarUtil, uProtect, uHelper;

  type
  { TAppUpd }
  TAppUpd = class(TCustomApplication)
  private
    fLog: string;
  protected
    procedure DoRun(); override;
    procedure Quit(aErr: integer = 0; const aMsg: string = '');
    function GetVerRemote(const aUrl: string): string;
    function GetCommandLine(): string;
    procedure AppProtect(const aPath: string);
    procedure Update(const aUrl: string);
    procedure ShowHelp(); virtual;
    procedure Log(const aStr: string);
    function DownloadWithCurl(const aUrl: string): string;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  end;

function TAppUpd.GetCommandLine(): string;
var
  i: Integer;
begin
  Result := ParamStr(0);
  for i := 1 to ParamCount do
    Result := Result + ' ' + ParamStr(i);
end;

procedure TAppUpd.Log(const aStr: string);
var
  Str: string;
  F: TextFile;
begin
  WriteLn(aStr);
  if (fLog.IsEmpty()) then
    Exit();

  AssignFile(F, fLog);
  if FileExists(fLog) then
    Append(F)
  else
    Rewrite(F);

  Str := Format('%s %s', [FormatDateTime('yy-mm-dd hh:nn:ss', Now()), aStr]);
  WriteLn(F, Str);
  CloseFile(F);
end;

procedure TAppUpd.Quit(aErr: integer = 0; const aMsg: string = '');
begin
  if (not aMsg.IsEmpty()) then
    Log(aMsg);

  if (HasOption('p', 'pause')) then
  begin
    WriteLn('press enter to quit');
    ReadLn();
  end;

  Terminate();
  Halt(aErr);
end;

procedure TAppUpd.AppProtect(const aPath: string);
var
  Tail, Tail2: TTail;
  Protect: TProtect;
begin
  Protect := TProtect.Create(aPath);
  Tail := Protect.ReadFileTail();
  if (Tail.Sign = cTailSign) then
  begin
    Log('Already protected ' + aPath);
    Quit();
  end;

  Tail := Protect.CalculateFileTail(0);
  Protect.WriteFileTail(Tail);

  Tail2 := Protect.ReadFileTail();
  Tail2 := Protect.CalculateFileTail(Tail2.BlockLen);
  if (Tail.CheckSum = Tail2.CheckSum) then
    Log(Format('Protected. CRC is %.8x', [Tail.CheckSum]))
  else
    Log(Format('Error. CRC mismatch %.8x %.8x', [Tail.CheckSum, Tail2.CheckSum]));

  Protect.Free();
end;

function TAppUpd.GetVerRemote(const aUrl: string): string;
var
  Str: string;
  Err: integer;
  Uri: TURI;
begin
  Err := GetUrlToString(aUrl, Result);
  if (Err <> 200) then
  begin
    Uri := ParseURI(aUrl);
    if (not Uri.Password.IsEmpty()) then
    begin
      Uri.Password := 'xxx';
      EncodeURI(Uri);
      Str := EncodeURI(Uri);
    end
    else
    begin
      Str := aUrl;
      Quit(1, Format('Error %d downloading %s', [Err, Str]));
    end;
  end;
end;

function TAppUpd.DownloadWithCurl(const aUrl: string): string;
const
  cCurl = 'addons\curl.exe';
var
  Param, Output: TStringList;
  Process: TProcess;
begin
  if (not FileExists(cCurl)) then
    Quit(1, 'File not exists ' + cCurl);

  Result := ConcatPaths([GetTempDir(), ExtractFileName(aURL)]);

  Param := TStringList.Create();
  Param.Add('-L');
  Param.Add('-o');
  Param.Add(Result.FileQuoted());
  Param.Add(aUrl);
  Process := ExecProcess(cCurl, Param);

  if (Process.ExitStatus <> 0) then
  begin
    Output := TStringList.Create();
    Output.LoadFromStream(Process.Stderr);
    Log(Output.Text);
    Output.LoadFromStream(Process.Output);
    Log(Output.Text);
    Output.Free();

    Quit(1, 'Error ' + cCurl);
  end;
end;

procedure TAppUpd.Update(const aUrl: string);
var
  FileZip, Str, Dir: string;
  Delay: integer;
begin
  Dir := GetOptionValue(#0, 'dir');
  if (Dir.IsEmpty()) then
    Quit(1, '--dir is empty');
  Log(Format('Directory to extract %s', [Dir]));

  // first download file. It takes some time to leave master application
  Log(Format('Download from %s', [aUrl]));
  // Unknown exception when run from another process. so use curl to download. fuck!
  //Log('-x1');
  FileZip := GetUrlToFile(aUrl, GetTempDir());
  //Log('-x2');
  // Unknown exception when run from another process even with curl fuck!
  //FileZip := DownloadWithCurl(aUrl);

  Str := GetOptionValue(#0, 'delay');
  if (Str.IsEmpty()) then
    Str := '0';
  Log(Format('Delay %s', [Str]));
  Delay := StrToInt(Str);
  Sleep(Delay);

  Str := GetOptionValue(#0, 'pid');
  if (not Str.IsEmpty()) then
  begin
    Log(Format('WaitProcess PID %s', [Str]));
    WaitProcess(Str.ToInteger());
    //Sleep(Delay);
  end;

  Log(Format('UnZipToDir %s to %s', [FileZip, Dir]));
  UnZipToDir(FileZip, Dir);

  Log(Format('DeleteFile %s', [FileZip]));
  DeleteFile(FileZip);

  Str := GetOptionValue(#0, 'app');
  if (not Str.IsEmpty()) then
  begin
    if (not FileExists(Str)) then
      Quit(1, 'File not exists ' + Str);

    Log(Format('Run applacation %s', [Str]));
    ExecProcess(Str);
  end;

  Log('Exit update');
end;

procedure TAppUpd.DoRun();
var
  Str: string;
  Parts: TStringArray;
begin
  if (ParamCount = 0) then
  begin
    ShowHelp();
    Quit();
  end;

  fLog := '';
  if (HasOption(#0, 'log')) then
  begin
    fLog := GetOptionValue(#0, 'log');
    if (fLog.IsEmpty()) then
      fLog := GetAppName() + '.log';
  end;

  Str := GetOptionValue(#0, 'crc');
  if (not Str.IsEmpty()) then
  begin
    if (not FileExists(Str)) then
      Quit(1, 'File not exists ' + Str);
    AppProtect(Str);
    Quit();
  end;

  Str := GetOptionValue(#0, 'app_ver');
  if (not Str.IsEmpty()) then
  begin
    if (not FileExists(Str)) then
      Quit(1, 'File not exists ' + Str);

    Str := GetExeVer(Str);
    Log(Str);
    Quit();
  end;

  Str := GetOptionValue(#0, 'app_build');
  if (not Str.IsEmpty()) then
  begin
    if (not FileExists(Str)) then
      Quit(1, 'File not exists ' + Str);

    Str := GetExeVer(Str);
    Parts := Str.Split('.');
    Log(Parts[High(Parts)]);
    Quit();
  end;

  Str := GetOptionValue(#0, 'url');
  if (not Str.IsEmpty()) then
  begin
    Update(Str);
    Quit();
  end;

  Quit();
end;

procedure TAppUpd.ShowHelp();
var
  AppName: string;
begin
  AppName := GetAppName();
  WriteLn(AppName, ' ver ', GetAppVer(), ' (', {$I %DATE%} + ')');
  WriteLn(AppName + ' --app=app.exe --dir=path\app --pid=<app PID> --delay=2000 --url=http://site.com/update.zip');
  WriteLn('options:');
  WriteLn('--app       application to start after update');
  WriteLn('--app_ver   get app version (also --app_build)');
  WriteLn('--delay     delay in ms before start app');
  WriteLn('--dir       directory to extract ZIP archive');
  WriteLn('--log       log to file');
  WriteLn('--pid       process ID to wait for free');
  WriteLn('--url       remote ZIP file address');
end;

constructor TAppUpd.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  StopOnException:=True;
end;

destructor TAppUpd.Destroy;
begin
  inherited Destroy();
end;

var
  AppUpd: TAppUpd;
  {$R *.res}

begin
  AppUpd := TAppUpd.Create(nil);
  AppUpd.Title:='vAppUpd';
  AppUpd.Run();
  AppUpd.Free();
end.

