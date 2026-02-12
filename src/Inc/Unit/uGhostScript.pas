unit uGhostScript;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Process, Classes,
  uFMessageShow;

const
  cGS_Dir = 'addons\gs';

function GS_OptimizePdf(const aFileIn, aFileOut: String): Integer;
function GS_JpgToPdf(const aFileIn, aFileOut: String): Integer;

implementation

function GS_Exec(aParam: TStrings): Integer;
var
  Process: TProcess;
  FilePath, ExeDir, Str: string;
  Output: TStringList;
begin
  ExeDir := ExtractFilePath(ParamStr(0));
  FilePath := ExeDir + cGS_Dir + PathDelim + 'gswin32c.exe';

  if (not FileExists(FilePath)) then
    raise Exception.Create('Не знайдено ' + FilePath);

  Output := TStringList.Create();
  Process := TProcess.Create(nil);
  try
    Process.Executable := FilePath;
    Process.Parameters := aParam;
    Process.CurrentDirectory := ExeDir;
    Process.Options := [poUsePipes, poWaitOnExit];
    Process.ShowWindow := swoHide;
    Process.Execute();
    Result := Process.ExitStatus;

    //Output.LoadFromStream(Process.Stderr);
    Output.LoadFromStream(Process.Output);
    Str := Output.Text;
  finally
    Process.Free();
    Output.Free();
  end;
end;

function GS_OptimizePDF(const aFileIn, aFileOut: String): Integer;
var
  Params: TStringList;
begin
  try
    Params := TStringList.Create();
    Params.Add('-sDEVICE=pdfwrite');
    Params.Add('-dCompatibilityLevel=1.4');
    Params.Add('-dPDFSETTINGS=/ebook');
    Params.Add('-dNOPAUSE');
    Params.Add('-dQUIET');
    Params.Add('-dBATCH');
    Params.Add('-sOutputFile=' + aFileOut);
    Params.Add(aFileIn);
    Result := GS_Exec(Params);
  finally
    Params.Free();
  end;
end;

function GS_JpgToPdf(const aFileIn, aFileOut: String): Integer;
var
  Params: TStringList;
  FilePath, FilePathUnix: string;
begin
  FilePath := cGS_Dir + PathDelim + 'viewjpeg.ps';
  if (not FileExists(FilePath)) then
    raise Exception.Create('Не знайдено ' + FilePath);

  FilePathUnix := StringReplace(aFileIn , '\', '/', [rfReplaceAll]);
  try
    Params := TStringList.Create();
    Params.Add('-dNOSAFER');
    Params.Add('-sDEVICE=pdfwrite');
    Params.Add('-dCompatibilityLevel=1.4');
    Params.Add('-dPDFSETTINGS=/screen');
    Params.Add('-dNOPAUSE');
    Params.Add('-dBATCH');
    Params.Add('-sOutputFile=' + aFileOut);
    Params.Add(FilePath + ' -c "(' + FilePathUnix  + ')" viewJPEG');
    FMessageShow.Memo1.Lines := Params;
    FMessageShow.Show();
    Result := GS_Exec(Params);
  finally
    Params.Free();
  end;
end;

end.

