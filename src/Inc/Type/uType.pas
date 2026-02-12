// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uType;

{$mode objfpc}{$H+}

interface

uses
    classes, fgl;

type
    TStringArray = array of string;

    TStringIntMap = specialize TFPGMap<string, Integer>;

    TStringListEx = class(TStringList)
    public
      constructor Create(aArrStr : TStringArray);
    end;


implementation

constructor TStringListEx.Create(aArrStr : TStringArray);
var
  i:  Integer;
begin
  inherited Create();

  for i := Low(aArrStr) to High(aArrStr) do
      Add(aArrStr[i]);
end;

end.
