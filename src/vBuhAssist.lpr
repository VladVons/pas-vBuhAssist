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
  Forms, uFMain, uFAbout, uFMedocCheckDocs, uWinManager, uGenericMatrix,
  uDmFbConnect, uWinReg, uLicence, uFLicense, uSys, uGhostScript, uFOptimizePDF,
  uSettings, uVarUtil, uLog, uConst, uFLogin, uFMessageShow;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize();
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TDmFbConnect, DmFbConnect);
  Application.CreateForm(TFLogin, FLogin);
  Application.CreateForm(TFMessageShow, FMessageShow);
  Application.Run();
end.

