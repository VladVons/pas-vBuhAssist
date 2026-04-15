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
  AST: TList;
  Ctx: TContext;
  OutS, Tpl: string;
begin
  Ctx := TContext.Create;

  Ctx.Load(
    '{"age":20, "gender":1, "town": "london"}'
  );

  Tpl := StrFromFile('MyTest.txt');

  AST := TMiniJinja.Parse(Tpl);
  OutS := TMiniJinja.Render(AST, Ctx);

  WriteLn(OutS);

  AST.Free();
  Ctx.Free();
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

