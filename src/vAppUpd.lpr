program vAppUpd;

{$mode objfpc}{$H+}
{$apptype console}

uses
  Classes, SysUtils, CustApp, opensslsockets, URIParser, fpjson, jsonparser,
  uSys, uHttp, uArchive, uVarUtil, uProtect;

type
  TAppUpd = class(TCustomApplication)
  protected
    procedure DoRun(); override;
    procedure Quit(aErr: Integer = 0; const aMsg: String = '');
    function GetVerRemote(const aUrl: String): String;
    procedure AppProtect(const aPath: String);
    procedure Update(const aUrl: String);
    procedure ShowHelp(); virtual;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy(); override;
  end;

var
  AppUpd: TAppUpd;
  {$R *.res}

{ TAppUpd }
procedure TAppUpd.Quit(aErr: Integer = 0; const aMsg: String = '');
begin
  if (not aMsg.IsEmpty()) then
    WriteLn(aMsg);

  if (HasOption('p', 'pause')) then
  begin
    WriteLn('press enter to quit');
    ReadLn();
  end;

  Terminate();
  Halt(aErr);
end;

procedure TAppUpd.AppProtect(const aPath: String);
var
  Tail, Tail2: TTail;
  Protect: TProtect;
begin
  Protect := TProtect.Create(aPath);
  Tail := Protect.ReadFileTail();
  if (Tail.Sign = cTailSign) then
  begin
     WriteLn('Already protected ' + aPath);
     Quit();
  end;

  Tail := Protect.CalculateFileTail(0);
  Protect.WriteFileTail(Tail);

  Tail2 := Protect.ReadFileTail();
  Tail2 := Protect.CalculateFileTail(Tail2.BlockLen);
  if (Tail.CheckSum = Tail2.CheckSum) then
    WriteLn('Protected. CRC is ', IntToHex(Tail.CheckSum))
  else
    WriteLn('Error. CRC mismatch ', IntToHex(Tail.CheckSum), ' ', IntToHex(Tail2.CheckSum));

  Protect.Free();
end;

function TAppUpd.GetVerRemote(const aUrl: String): String;
var
  Str: String;
  Err: Integer;
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
    end else begin
      Str := aUrl;
      Quit(1, format('Error %d downloading %s', [Err, Str]));
    end;
  end
end;

procedure TAppUpd.Update(const aUrl: String);
var
  FileZip, Str: string;
begin
  //GetUrlToFile('https://collector:col2024@download.1x1.com.ua/public/update/vBuhAssist/vBuhAssist_35.exe.zip');
  FileZip := GetUrlToFile(aUrl, GetTempDir());

  Str := GetOptionValue(#0, 'pid');
  if (not Str.IsEmpty()) then
    WaitProcess(Str.ToInteger());

  Str := GetOptionValue(#0, 'delay');
  if (Str.IsEmpty()) then
    Str := '0';
  Sleep(StrToInt(Str));

  Str := GetOptionValue(#0, 'dir');
  UnZipToDir(FileZip, Str);
  DeleteFile(FileZip);

  Str := GetOptionValue(#0, 'app');
  ExecProcess(Str, Nil);
end;

procedure TAppUpd.DoRun();
var
  Str: String;
begin
  if (ParamCount = 0) then
  begin
    ShowHelp();
    Quit();
  end;

  Str := GetOptionValue(#0, 'crc');
  if (not Str.IsEmpty()) then
  begin
    AppProtect(Str);
    Quit();
  end;

  Str := GetOptionValue(#0, 'url');
  if (not Str.IsEmpty()) then
  begin
    Update(Str);
    Quit();
  end;


  //Update('https://collector:col2024@download.1x1.com.ua/private/update/Test/ver.json');

  //WriteLn(Str);
  //Str := GetOptionValue('s', 'sleep');
  //UnZipToDir('c:\temp\pdf_small.zip', 'c:\temp\12\34');
  Quit();
end;

constructor TAppUpd.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  StopOnException:=True;
end;

destructor TAppUpd.Destroy();
begin
  inherited Destroy();
end;

procedure TAppUpd.ShowHelp();
begin
  WriteLn(GetAppName(), ' ', GetAppVer(), ' ', {$I %DATE%});
  WriteLn('options:');
  WriteLn('--app     application to start after update');
  WriteLn('--dir     directory to extract ZIP archive');
  WriteLn('--pause   wait for key press before quit');
  WriteLn('--pid     process ID to wait for free');
  WriteLn('--delay   delay in ms before unzip');
  WriteLn('--url     remote ZIP file address ');
end;

begin
  AppUpd:=TAppUpd.Create(nil);
  AppUpd.Title:='App Updater';
  AppUpd.Run();
  AppUpd.Free();
end.

