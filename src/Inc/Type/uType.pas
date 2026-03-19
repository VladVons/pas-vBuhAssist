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
    TIntegerArray = array of Integer;
    TStringIntMap = specialize TFPGMap<string, integer>;

    //TStringHelper = type helper for <T>
    //  function Len: integer;
    //end;

implementation

//function TStringHelper.Len(): integer;
//begin
//  Result := Length(Self);
//end;

end.
