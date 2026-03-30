// Created: 2026.03.25
// Author: Vladimir Vons <VladVons@gmail.com>

unit uHelperVcl;

{$mode objfpc}{$H+}
{$modeswitch typehelpers}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, TypInfo, Variants, fpjson;

type
  TControlHelper = class helper for TControl
  public
    function GetInputName(): string;
    function GetJName(aJObj: TJSONObject; aIdx: integer): string;
    procedure GetJProperty(aJObj: TJSONObject; const aProp: string; aKey: string = '');
    function SetProperty(const aName: string; aVal: variant): boolean;
    procedure SetJProperty(aJObj: TJSONObject; const aProp: string; aKey: string = '');
  end;

  TComboBoxHelper = class helper for TComboBox
    procedure Add(aJObj: TJSONObject);
    function GetJObj(): TJSONObject;
    procedure ClearItems();
    function HasNext(): Boolean;
    function HasPrev(): Boolean;
    function Last(): Boolean;
    procedure Next(aStep: integer);
  end;

implementation

// --- TControlHelper

function TControlHelper.GetJName(aJObj: TJSONObject; aIdx: integer): string;
begin
  Result := aJObj.Get('name', Format('%s_%d', [self.ClassName, aIdx]));
end;

function TControlHelper.GetInputName(): string;
const
  cArr: TStringArray = ('text', 'value', 'checked');
var
  i: integer;
begin
  for i := 0 to Length(cArr) do
    if (GetPropInfo(self, cArr[i]) <> nil) then
      Exit(cArr[i]);

  Result := '';
end;

function TControlHelper.SetProperty(const aName: string; aVal: variant): boolean;
var
  i: integer;
  Part: string;
  Parts: TStringArray;
  PropInfo: PPropInfo;
  Ctrl: TObject;
begin
  Ctrl := self;
  Parts := aName.Split(['.']);
  for i := 0 to High(Parts) do
  begin
     Part := Parts[i];
     PropInfo := GetPropInfo(Ctrl, Part);
     if (PropInfo = nil) then
       Exit(false);

     if (i < High(Parts)) then
     begin
       if (PropInfo^.PropType^.Kind <> tkClass) then
         Exit(false);
       Ctrl := GetObjectProp(Ctrl, PropInfo);
     end;
  end;

  case PropInfo^.PropType^.Kind of
    tkEnumeration:
      SetOrdProp(Ctrl, PropInfo, GetEnumValue(PropInfo^.PropType, VarToStr(aVal)));
    tkSet:
      SetSetProp(Ctrl, PropInfo, VarToStr(aVal));
  else
    SetPropValue(Ctrl, Part, aVal);
  end;

  Result := True;
end;

procedure TControlHelper.SetJProperty(aJObj: TJSONObject; const aProp: string; aKey: string);
var
  JData: TJSONData;
begin
  if (aKey.IsEmpty()) then
    aKey := aProp;

  JData := aJObj.Find(aKey);
  if (JData <> nil) then
    case JData.JSONType of
      jtNumber:
        SetProperty(aProp, JData.AsFloat);
      jtString:
        SetProperty(aProp, JData.AsString);
      jtBoolean:
        SetProperty(aProp, JData.AsBoolean);
    end;
end;

procedure TControlHelper.GetJProperty(aJObj: TJSONObject; const aProp: string; aKey: string);
var
  V: Variant;
  PropInfo: PPropInfo;
begin
  if (aKey.IsEmpty()) then
    aKey := aProp;

  PropInfo := GetPropInfo(self, aProp);
  if (PropInfo = nil)
    then Exit();

  V := GetPropValue(self, PropInfo, True);
  case PropInfo^.PropType^.Kind of
    tkInteger, tkInt64: aJObj.Add(aKey, Integer(V));
    tkFloat: aJObj.Add(aKey, Double(V));
    tkBool: aJObj.Add(aKey, Boolean(V));
  else
    aJObj.Add(aKey, VarToStr(V));
  end;
end;

//--- TComboBoxHelper 2026.03.29

procedure TComboBoxHelper.Add(aJObj: TJSONObject);
begin
  Items.AddObject(aJObj.Get('text', ''), aJObj);
end;

function TComboBoxHelper.GetJObj(): TJSONObject;
begin
  if (ItemIndex < 0) then
    Exit(nil);

  Result := TJSONObject(Items.Objects[ItemIndex]);
end;

procedure TComboBoxHelper.Next(aStep: integer);
var
  Idx: Integer;
begin
  if (Items.Count = 0) then
    Exit();

  if (ItemIndex < 0) then
    Idx := 0
  else
    Idx := ItemIndex;

  Inc(Idx, aStep);
  if (Idx < 0) then
    Idx := 0
  else if Idx >= Items.Count then
    Idx := Items.Count - 1;

  ItemIndex := Idx;
end;

function TComboBoxHelper.Last(): Boolean;
begin
  Result := (Items.Count > 0) and (ItemIndex >= 0) and (ItemIndex = Items.Count - 1);
end;

function TComboBoxHelper.HasNext(): Boolean;
begin
  Result := (Items.Count > 0) and (ItemIndex < Items.Count - 1);
end;

function TComboBoxHelper.HasPrev(): Boolean;
begin
  Result := (Items.Count > 0) and (ItemIndex > 0);
end;

procedure TComboBoxHelper.ClearItems();
var
  i: Integer;
begin
  for i := 0 to Items.Count - 1 do
    Items.Objects[i].Free();
end;

end.

