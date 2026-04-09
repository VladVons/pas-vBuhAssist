// Created: 2026.04.09
// Author: Vladimir Vons <VladVons@gmail.com>

unit uMacros;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, RegExpr,
  uHelper;

type
  TMacrosMask = record
    Prefix: string;
    Suffix: string;
  end;

  TOnMacro = function (const aStr, aFind, aReplace: string; const fMMask: TMacrosMask): string of object;

  TMacros = class
  private
    fMMask: TMacrosMask;
    fStr: string;
    fSL: TStringList;
    function Replace(const aStr, aFind, aRepl: string): string;
    function ReplaceDef(const aStr, aFind, aRepl: string): string;
    function GetList(): TStringList;
  public
    OnMacro: TOnMacro;
    constructor Create(const aPrefix: string = '{{'; const aSuffix: string = '}}');
    destructor Destroy(); override;

    procedure Load(const aStr: string);
    function Parse(const aNames, aValues: TStringArray): string;
    function Parse(aDict: TStringList): string;
    function Parse(aObj: TJSONObject): string;

    property Str: string read fStr;
    Property Items: TStringList read fSL;
  end;

implementation

constructor TMacros.Create(const aPrefix: string = '{{'; const aSuffix: string = '}}');
begin
  fMMask.Prefix := aPrefix;
  fMMask.Suffix := aSuffix;
end;

destructor TMacros.Destroy();
begin
  FreeAndNil(fSL);
  inherited;
end;

procedure TMacros.Load(const aStr: string);
begin
  fStr := aStr;

  FreeAndNil(fSL);
  fSL := GetList();
end;

function TMacros.ReplaceDef(const aStr, aFind, aRepl: string): string;
begin
  if (aRepl.IsEmpty()) then
    Result := aStr
  else
    Result := StringReplace(aStr, fMMask.Prefix + aFind + fMMask.Suffix, aRepl, [rfReplaceAll]);
end;

function TMacros.Replace(const aStr, aFind, aRepl: string): string;
begin
  if (Assigned(OnMacro)) then
    Result := OnMacro(aStr, aFind, aRepl, fMMask)
  else
    Result := ReplaceDef(aStr, aFind, aRepl);
end;

function TMacros.Parse(const aNames, aValues: TStringArray): string;
var
  i: integer;
begin
  if (System.Length(aNames) <> System.Length(aValues)) then
    raise Exception.Create('arrays length mismatch');

  Result := fStr;
  for i := 0 to System.Length(aNames) - 1do
    Result := Replace(Result, aNames[i], aValues[i]);
end;

function TMacros.Parse(aDict: TStringList): string;
var
  i: integer;
begin
  Result := fStr;
  for i := 0 to aDict.Count - 1 do
    Result := Replace(Result, aDict.Names[i], aDict.ValueFromIndex[i]);
end;

function TMacros.Parse(aObj: TJSONObject): string;
var
  i: integer;
  Find, Repl: string;
begin
  Result := fStr;
  for i := 0 to aObj.Count - 1 do
  begin
    Find := aObj.Names[i];
    Repl := aObj.GetAsString(Find, '').Replace('"', '`');
    Result := Replace(Result, Find, Repl);
  end;
end;

function TMacros.GetList(): TStringList;
var
  re: TRegExpr;
begin
  Result := TStringList.Create();
  re := TRegExpr.Create();
  try
    re.Expression := Format('%s(.+?)%s',[fMMask.Prefix.EscapeRegExp(), fMMask.Suffix.EscapeRegExp()]);
    if (re.Exec(fStr)) then
      repeat
        Result.Add(re.Match[1]);
      until not re.ExecNext();
  finally
    re.Free();
  end;
end;

end.
