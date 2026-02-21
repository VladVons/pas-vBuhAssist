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
  Forms, uFMain, uFAbout, uFMedocCheckDocs, uWinManager,
  uDmCommon, uWinReg, uLicence, uFLicense, uSys, uGhostScript, uFOptimizePDF,
  uSettings, uVarUtil, uLog, uConst, uFLogin, uFMessageShow, uExceptionHandler,
  uType, uCrypt, uFormState, uMedoc, uFSettings, uQuery;

{$R *.res}
begin
  AppException := TAppException.Create();
  Application.OnException := @AppException.Handler;

  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  //OneInstanceOnly(cAppName);
  OneInstance := TOneInstance.Create();
  OneInstance.Check();

  Application.Initialize();
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TDmCommon, DmCommon);
  Application.Run();
end.

