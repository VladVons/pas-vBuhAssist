unit uProtectTimer;

{$mode ObjFPC}{$H+}

interface

uses
  uProtect, ExtCtrls;

type
  TProtectTimer = class(TProtect)
  private
    Timer1: TTimer;
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
  Timer1 := TTimer.Create(Nil);
  Timer1.Enabled := False;
end;

destructor TProtectTimer.Destroy();
begin
  Timer1.Free();
  inherited Destroy;
end;

procedure TProtectTimer.TimerRunRnd(aMod: boolean; aInterval: Integer = 10000 );
begin
  Timer1.Enabled := aMod;
  Timer1.Interval := aInterval + Random(aInterval);
  Timer1.OnTimer := @OnTimer;
end;

procedure TProtectTimer.OnTimer(Sender: TObject);
begin
  Timer1.Enabled := False;
  ReadCRC();
end;

end.

