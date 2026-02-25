// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uType;

{$mode objfpc}{$H+}
{$modeswitch typehelpers}

interface

uses
    classes, fgl;

type
    TStringArray = array of string;

    TStringIntMap = specialize TFPGMap<string, integer>;

    TStringListEx = class(TStringList)
    public
      constructor Create(aArrStr : TStringArray);
    end;

    //TStringHelper = type helper for <T>
    //  function Len: integer;
    //end;

implementation

constructor TStringListEx.Create(aArrStr : TStringArray);
var
  i:  integer;
begin
  inherited Create();

  for i := Low(aArrStr) to High(aArrStr) do
      Add(aArrStr[i]);
end;


//function TStringHelper.Len(): integer;
//begin
//  Result := Length(Self);
//end;

end.
