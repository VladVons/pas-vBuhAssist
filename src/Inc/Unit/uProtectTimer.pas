// Created: 2026.02.23
// Author: Vladimir Vons <VladVons@gmail.com>

unit uProtectTimer;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, ExtCtrls,
  uProtect;

type
  TProtectTimer = class(TProtect)
  private
    fTimer: TTimer;
    procedure OnTimer(Sender: TObject);
  public
    constructor Create(const aFile: String);
    destructor Destroy(); override;
    procedure TimerRunRnd(aMod: boolean; aInterval: Integer = 10000 );
  end;

var
  ProtectTimer: TProtectTimer;

implementation

constructor TProtectTimer.Create(const aFile: String);
begin
  inherited;

  Randomize();
  fTimer := TTimer.Create(Nil);
  fTimer.Enabled := False;
end;

destructor TProtectTimer.Destroy();
begin
  FreeAndNil(fTimer);
  inherited;
end;

procedure TProtectTimer.TimerRunRnd(aMod: boolean; aInterval: Integer = 10000 );
begin
  fTimer.Enabled := aMod;
  fTimer.Interval := aInterval + Random(aInterval);
  fTimer.OnTimer := @OnTimer;
end;

procedure TProtectTimer.OnTimer(Sender: TObject);
begin
  fTimer.Enabled := False;
  ReadCRC();
end;

end.

