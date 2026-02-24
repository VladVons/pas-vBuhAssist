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
    fFileName: string;
    fMemo: TMemo;
    procedure ToFile(const aMsg: string);
  public
    constructor Create(aMemo: TMemo);
    procedure Print(aType: Char; const aMsg: string);
  end;

var
  Log: TLog = Nil;

implementation

constructor TLog.Create(aMemo: TMemo);
begin
  fMemo := aMemo;
  fFileName := GetAppFile('app.log');
end;

procedure TLog.ToFile(const aMsg: string);
begin
  FileAppendText(fFileName, aMsg);
end;

procedure TLog.Print(aType: Char; const aMsg: String);
var
  Msg: String;
begin
  Msg := FormatDateTime('yy-mm-dd hh:nn:ss', Now()) + ', ' + aType + ', ' + aMsg;
  fMemo.Lines.Add(Msg);
  ToFile(Msg);
end;

end.

