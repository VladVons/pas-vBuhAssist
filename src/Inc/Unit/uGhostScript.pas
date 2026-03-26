// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uGhostScript;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Process, Classes,
  uSys, uHelper;

const
  cGS_Dir = 'addons\gs';

function GS_OptimizePdf(const aFileIn, aFileOut: string): integer;
function GS_JpgToPdf(const aFileIn, aFileOut: string): integer;

implementation

function GS_Exec(aParam: TStrings): integer;
var
  Process: TProcess;
  FilePath, Dir: string;
  Output: TStringList;
begin
  Output := TStringList.Create();

  Dir := ExtractFilePath(ParamStr(0));
  FilePath := ConcatPaths([Dir, cGS_Dir, 'gswin32c.exe']);
  try
    Process := ExecProcess(FilePath, aParam);
    Result := Process.ExitStatus;

    Output.LoadFromStream(Process.Stderr);
    Output.LoadFromStream(Process.Output);
    //WriteLn(Output.Text);
  finally
    Process.Free();
    Output.Free();
  end;
end;

function GS_OptimizePDF(const aFileIn, aFileOut: string): integer;
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

function GS_JpgToPdf(const aFileIn, aFileOut: string): integer;
var
  Params: TStringList;
  FilePath, FilePathUnix: string;
begin
  FilePath := ConcatPaths([cGS_Dir, 'viewjpeg.ps']);
  if (not FilePath.FileExists()) then
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
    Result := GS_Exec(Params);
  finally
    Params.Free();
  end;
end;

end.

