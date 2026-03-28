// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uGhostScript;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Process,
  uSys, uHelper;

const
  cGS_Dir = 'addons' + PathDelim + 'gs';

function GS_OptimizePdf(const aFileIn, aFileOut: string): integer;
function GS_JpgToPdf(const aFileIn, aFileOut: string): integer;
function GS_BmpToPdf(const aFileIn, aFileOut: string): integer;

implementation

function GS_Exec(aParam: TStrings): integer;
var
  Process: TProcess;
  Str, FilePath, Dir: string;
  Output: TStringList;
begin
  Output := TStringList.Create();

  Dir := ExtractFilePath(ParamStr(0));
  FilePath := ConcatPaths([Dir, cGS_Dir, 'gswin32c.exe']);
  try
    Process := ExecProcess(FilePath, aParam, [poWaitOnExit, poUsePipes]);
    Result := Process.ExitStatus;
    if (Result <> 0) then
    begin
      //Output.LoadFromStream(Process.Output);
      //Str := Output.Text;
      Output.LoadFromStream(Process.Stderr);
      Str := Format('Process error (%d): %s', [Result, Output.Text]);
      raise Exception.Create(Str);
    end;
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
    Params.Add('-dPDFSETTINGS=/ebook');
    Params.Add('-dNOPAUSE');
    Params.Add('-dQUIET');
    Params.Add('-dBATCH');
    Params.Add('-sOutputFile=' + aFileOut.FileQuoted());
    Params.Add(aFileIn.FileQuoted());
    Result := GS_Exec(Params);
  finally
    Params.Free();
  end;
end;

function GS_ScriptToPdf(const aFileIn, aFileOut, aFileScript, aScript: string): integer;
var
  Params: TStringList;
  FilePath, FilePathUnix: string;
begin
  FilePath := ConcatPaths([ExtractFilePath(ParamStr(0)), cGS_Dir, aFileScript]);
  if (not FilePath.FileExists()) then
    raise Exception.Create('Не знайдено ' + FilePath);

  FilePathUnix := aFileIn.Replaces(['\'], ['/']).FileQuoted();

  Params := TStringList.Create();
  Params.Add('-dNOSAFER');
  Params.Add('-sDEVICE=pdfwrite');
  Params.Add('-dPDFSETTINGS=/screen');
  Params.Add('-dNOPAUSE');
  Params.Add('-dBATCH');
  Params.Add('-sOutputFile=' + aFileOut.FileQuoted());
  Params.Add(Format('%s -c (%s) %s', [FilePath.FileQuoted(), FilePathUnix, aScript]));
  try
    Result := GS_Exec(Params);
  finally
    Params.Free();
  end;
end;

function GS_JpgToPdf(const aFileIn, aFileOut: string): integer;
begin
  Result := GS_ScriptToPdf(aFileIn, aFileOut, 'viewjpeg.ps', 'viewJPEG');
end;

function GS_BmpToPdf(const aFileIn, aFileOut: string): integer;
begin
  //Result := GS_ScriptToPdf(aFileIn, aFileOut, 'view???.ps', 'view???');
end;

end.

