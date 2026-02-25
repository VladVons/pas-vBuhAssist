// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uLog;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, StdCtrls, SysUtils,
  uUserData, uSys;

type
  TLog = class(TUserData)
  protected
    fMemo: TMemo;
    procedure ToFile(const aMsg: string);
  public
    constructor Create(const aFile: string; aMemo: TMemo);
    procedure Print(aType: char; const aMsg: string);
  end;

var
  Log: TLog = Nil;

implementation

constructor TLog.Create(const aFile: string; aMemo: TMemo);
begin
  inherited Create(aFile);
  fMemo := aMemo;
end;

procedure TLog.ToFile(const aMsg: string);
begin
  FileAppendText(fFile, aMsg);
end;

procedure TLog.Print(aType: char; const aMsg: string);
var
  Msg: string;
begin
  Msg := FormatDateTime('yy-mm-dd hh:nn:ss', Now()) + ', ' + aType + ', ' + aMsg;
  fMemo.Lines.Add(Msg);
  ToFile(Msg);
end;

end.

