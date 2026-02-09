unit uVarUtil;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

function ExtractLatin(const aString: string): string;

implementation

uses RegExpr;

function ExtractLatin(const aString: string): string;
var
  R: TRegExpr;
begin
  Result := '';
  R := TRegExpr.Create();
  try
    R.Expression := '[A-Za-z]';
    if R.Exec(aString) then
      repeat
        Result := Result + R.Match[0];
      until not R.ExecNext;
  finally
    R.Free();
  end;
end;

end.

