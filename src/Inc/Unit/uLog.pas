unit uLog;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, StdCtrls, SysUtils;

type
  TLog = class
  protected
    FileLog: string;
    Memo: TMemo;
    procedure ToFile(const aMsg: string);
  public
    constructor Create(aMemo: TMemo);
    procedure Print(const aMsg: string);
  end;

var
  Log: TLog;

implementation

constructor TLog.Create(aMemo: TMemo);
var
  DirLog, FileBase: string;
begin
  inherited Create();
  Memo := aMemo;

  FileBase := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  DirLog := GetEnvironmentVariable('ProgramData') + PathDelim + FileBase;
  if not DirectoryExists(DirLog) then
     ForceDirectories(DirLog);

  self.FileLog := DirLog + PathDelim + FileBase + '.log';
end;

procedure TLog.ToFile(const aMsg: string);
var
  F: TextFile;
begin
  AssignFile(F, self.FileLog);
  // Додаємо рядок у кінець файлу
  if FileExists(self.FileLog) then
    Append(F)
  else
    Rewrite(F);

  try
    Writeln(F, aMsg);
  finally
    CloseFile(F);
  end;
end;

procedure TLog.Print(const aMsg: String);
var
  Str: String;
begin
  Str := FormatDateTime('yy-mm-dd hh:nn:ss', Now()) + ' '+ aMsg;
  Memo.Lines.Add(Str);
end;

end.

