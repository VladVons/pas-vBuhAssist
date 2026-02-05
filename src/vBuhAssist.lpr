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
  Forms, uFMain, uFAbout, uFMedocCheckDocs, uForms, uMatrix, uDmFbConnect
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize();
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TFAbout, FAbout);
  Application.CreateForm(TDmFbConnect, DmFbConnect);
  Application.CreateForm(TFMedocCheckDocs, FMedocCheckDocs);
  Application.Run();
end.

