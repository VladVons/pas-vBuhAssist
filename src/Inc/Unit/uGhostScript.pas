unit uGhostScript;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Process;

function ExecOptimizePDF(const aFileIn, aFileOut: String): Integer;

implementation

function ExecOptimizePDF(const aFileIn, aFileOut: String): Integer;
var
  P: TProcess;
  GSPath, ExeDir: string;
begin
  ExeDir := ExtractFilePath(ParamStr(0));
  GSPath := ExeDir + 'addons\gs\gswin32c.exe';

  if (not FileExists(GSPath)) then
    raise Exception.Create('Не знайдено ' + GSPath);

  P := TProcess.Create(nil);
  try
    P.Executable := GSPath;

    P.Parameters.Add('-sDEVICE=pdfwrite');
    P.Parameters.Add('-dCompatibilityLevel=1.4');
    P.Parameters.Add('-dPDFSETTINGS=/ebook');
    P.Parameters.Add('-dNOPAUSE');
    P.Parameters.Add('-dQUIET');
    P.Parameters.Add('-dBATCH');
    P.Parameters.Add('-sOutputFile=' + aFileOut);
    P.Parameters.Add(aFileIn);

    P.CurrentDirectory := ExeDir;
    P.Options := [poNoConsole, poWaitOnExit];
    P.Execute();
    Result := P.ExitStatus;
  finally
    P.Free();
  end;
end;

end.

