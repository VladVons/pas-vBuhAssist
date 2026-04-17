program MyTest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  uSys, uTpl;

type

  TMyTest = class(TCustomApplication)
  protected
    procedure DoRun(); override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy(); override;
  end;


procedure TMyTest.DoRun();
var
  Ctx: TContext;
  OutS, Str: string;
  Tpl: TTpl;
begin
  Ctx := TContext.Create();
  Ctx.Load(
    '{"age": 20, "gender": 1, "location": {"town": "london"}}'
  );

  Str := StrFromFile('MyTest.txt');

  Tpl := TTpl.Create();
  Tpl.Parse(Str);
  OutS := Tpl.Render(Ctx);
  WriteLn(OutS);

  Tpl.Free();
  Ctx.Free();

  Terminate();
end;

constructor TMyTest.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
end;

destructor TMyTest.Destroy();
begin
  inherited Destroy();
end;

var
  Application: TMyTest;
begin
  Application:=TMyTest.Create(nil);
  Application.Title := 'My Application';
  Application.Run();
  Application.Free();
end.

