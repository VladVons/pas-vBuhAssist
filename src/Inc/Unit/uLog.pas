// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uLog;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, StdCtrls, SysUtils,
  uSys;

type
  TLog = class
  protected
    FileName: string;
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
begin
  Memo := aMemo;
  FileName := GetAppFile('app.log');
end;

procedure TLog.ToFile(const aMsg: string);
begin
  FileAppendText(FileName, aMsg);
end;

procedure TLog.Print(const aMsg: String);
var
  Msg: String;
begin
  Msg := FormatDateTime('yy-mm-dd hh:nn:ss', Now()) + ' ' + aMsg;

  //if (Memo.Height = 0) then
  //  Memo.Height := 75;
  Memo.Lines.Add(Msg);

  ToFile(Msg);
end;

end.

