// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

program vBuhAssist;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  opensslsockets,
  Interfaces, // this includes the LCL widgetset
  Forms,
  uFMain, uWinManager, uDmCommon, uExceptionHandler, uProtectDbg;

{$R *.res}
{$R vBuhAssist_Rc.res}
begin
  AppException := TAppException.Create('app.err');
  Application.OnException := @AppException.Handler;

  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  OneInstance := TOneInstance.Create();
  OneInstance.Check();

  Application.Initialize();
  Application.CreateForm(TDmCommon, DmCommon);
  Application.CreateForm(TFMain, FMain);
  Application.Run();
end.

