// Created: 2026.04.09
// Author: Vladimir Vons <VladVons@gmail.com>

unit uStrArr;

{$mode ObjFPC}{$H+}
//{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils;

type
  TStrArr = class;
  TFuncStrStr  = function(const aStr: string): string;
  TFuncStrBool = function(const aStr: string): boolean;

  TStrArrEnumerator = class
  private
    fList: TStrArr;
    fIndex: Integer;
    function GetCurrent(): string;
  public
    constructor Create(aList: TStrArr);
    destructor Destroy(); override;
    function MoveNext(): Boolean;
    property Current: string read GetCurrent;
  end;

  TStrArr = class
  private
    fData: TStringArray;
    function GetCount(): Integer; inline;
    function GetItem(aIdx: Integer): string; inline;
    procedure SetItem(aIdx: Integer; const aVal: string); inline;
    procedure QuickSort(aL, aR: Integer);
  public
    function Add(const aStr: string): TStrArr;
    function Add(const aArr: TStringArray): TStrArr;
    function Add(aStrArr: TStrArr): TStrArr;
    function All(aFunc: TFuncStrBool): Boolean;
    function Any(aFunc: TFuncStrBool): Boolean;
    function Clear(): TStrArr;
    function Delete(aIdx: Integer): TStrArr;
    function Join(const aDelim: string): string;
    function Find(const aStr: string; aIdx: integer = 0): Integer;
    function Filter(aFunc: TFuncStrBool): TStrArr;
    function First(): string;
    function Insert(aIdx: Integer; const aStr: string): TStrArr;
    function IsEmpty(): Boolean;
    function Last(): string;
    function Map(aFunc: TFuncStrStr): TStrArr;
    function Pop(): string;
    function Reverse(): TStrArr;
    function Shuffle(): TStrArr;
    function SetSize(aSize: Integer; const aFill: string = ''): TStrArr;
    function Sort(): TStrArr;
    function Swap(aIdx1, aIdx2: Integer): TStrArr;
    function ToArray(): TStringArray;

    function GetEnumerator(): TStrArrEnumerator;
    property Count: integer read GetCount;
    property Items[aIdx: Integer]: string read GetItem write SetItem; default;
  end;

implementation

// --- TStrArr
function TStrArr.GetEnumerator(): TStrArrEnumerator;
begin
  Result := TStrArrEnumerator.Create(Self);
end;

function TStrArr.GetCount: Integer;
begin
  Result := Length(fData);
end;

function TStrArr.GetItem(aIdx: Integer): string;
begin
  Result := fData[aIdx];
end;

procedure TStrArr.SetItem(aIdx: Integer; const aVal: string);
begin
  fData[aIdx] := aVal;
end;

function TStrArr.Add(const aStr: string): TStrArr;
var
  Len: Integer;
begin
  Len := Length(fData);
  SetLength(fData, Len + 1);
  fData[Len] := aStr;

  Result := self;
end;

function TStrArr.Add(const aArr: TStringArray): TStrArr;
var
  i, Len: Integer;
begin
  Len := Length(fData);
  SetLength(fData, Len + Length(aArr));

  for i := 0 to High(aArr) do
    fData[Len + i] := aArr[i];

  Result := self;
end;

function TStrArr.Add(aStrArr: TStrArr): TStrArr;
var
  Len, i: Integer;
begin
  Len := Length(fData);
  SetLength(fData, Len + aStrArr.Count);

  for i := 0 to aStrArr.Count - 1 do
    fData[Len + i] := aStrArr.fData[i];

  Result := self;
end;

function TStrArr.Any(aFunc: TFuncStrBool): Boolean;
var
  i: Integer;
begin
  for i := 0 to High(fData) do
  begin
    if (aFunc(fData[i])) then
      Exit(true);
  end;

  Result := false;
end;

function TStrArr.All(aFunc: TFuncStrBool): Boolean;
var
  i: Integer;
begin
  for i := 0 to High(fData) do
  begin
    if (not aFunc(fData[i])) then
      Exit(false);
  end;

  Result := true;
end;

function TStrArr.Insert(aIdx: Integer; const aStr: string): TStrArr;
var
  i, Len: Integer;
begin
  Len := Length(fData);
  if (aIdx < 0) or (aIdx > Len) then
    Exit();

  SetLength(fData, Len + 1);

  for i := Len downto aIdx + 1 do
    fData[i] := fData[i - 1];

  fData[aIdx] := aStr;
  Result := self;
end;

function TStrArr.IsEmpty(): Boolean;
begin
  Result := (Count = 0);
end;

function TStrArr.Last(): string;
begin
  if Count = 0 then
    Exit('');

  Result := fData[Count - 1];
end;

function TStrArr.Map(aFunc: TFuncStrStr): TStrArr;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    self[i] := aFunc(self[i]);

  Result := self;
end;

function TStrArr.Join(const aDelim: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Count - 1 do
  begin
    if (i > 0) then
      Result := Result + aDelim;
    Result := Result + fData[i];
  end;
end;

function TStrArr.Find(const aStr: string; aIdx: integer = 0): Integer;
var
  i: Integer;
begin
  for i := aIdx to Count - 1 do
    if fData[i] = aStr then
      Exit(i);
  Result := -1;
end;

function TStrArr.Filter(aFunc: TFuncStrBool): TStrArr;
var
  i: Integer;
begin
  Result := TStrArr.Create();
  for i := 0 to Count - 1 do
    if aFunc(fData[i]) then
      Result.Add(fData[i]);
end;

function TStrArr.First(): string;
begin
  if (Count = 0) then
    Result := ''
  else
    Result := self[0];
end;

function TStrArr.Delete(aIdx: Integer): TStrArr;
var
  i, Len: Integer;
begin
  Len := Length(fData);
  if (aIdx < 0) or (aIdx >= Len) then Exit;

  for i := aIdx to Len - 2 do
    fData[i] := fData[i + 1];

  SetLength(fData, Len - 1);
  Result := self;
end;

function TStrArr.Clear(): TStrArr;
begin
  SetLength(fData, 0);
  Result := self;
end;

function TStrArr.Swap(aIdx1, aIdx2: Integer): TStrArr;
var
  Str: string;
begin
  Str := fData[aIdx1];
  fData[aIdx1] := fData[aIdx2];
  fData[aIdx2] := Str;

  Result := self;
end;

function TStrArr.ToArray(): TStringArray;
begin
  Result := Copy(fData);
end;

function TStrArr.Sort(): TStrArr;
begin
  if (Length(fData) > 1) then
    QuickSort(0, High(fData));

  Result := self;
end;

// QuickSort Hoare
procedure TStrArr.QuickSort(aL, aR: Integer);
var
  i, j: Integer;
  Str: string;
begin
  i := aL;
  j := aR;
  Str := fData[(aL + aR) div 2];

  repeat
    while (fData[i] < Str) do
      Inc(i);

    while (fData[j] > Str) do
      Dec(j);

    if (i <= j) then
    begin
      Swap(i, j);
      Inc(i);
      Dec(j);
    end;
  until (i > j);

  if (aL < j) then
    QuickSort(aL, j);

  if (i < aR) then
    QuickSort(i, aR);
end;

function TStrArr.Pop(): string;
begin
  if (Count = 0) then
    Exit('');

  Result := fData[Count - 1];
  SetLength(fData, Count - 1);
end;

function TStrArr.Reverse(): TStrArr;
var
  i, j: Integer;
begin
  i := 0;
  j := High(fData);

  while (i < j) do
  begin
    Swap(i, j);
    Inc(i);
    Dec(j);
  end;

  Result := self;
end;

function TStrArr.Shuffle(): TStrArr;
var
  i, rnd: Integer;
begin
  for i := Count - 1 downto 1 do
  begin
    rnd := Random(i + 1);
    Swap(i, rnd);
  end;

  Result := self;
end;

function TStrArr.SetSize(aSize: Integer; const aFill: string = ''): TStrArr;
var
  Len, i: Integer;
begin
  Len := Length(fData);
  SetLength(fData, aSize);

  if (aSize > Len) then
    for i := Len to aSize - 1 do
      fData[i] := aFill;

  Result := self;
end;

//--- TStrArrEnumerator
constructor TStrArrEnumerator.Create(aList: TStrArr);
begin
  fList := aList;
  fIndex := -1;
end;

destructor TStrArrEnumerator.Destroy();
begin
  inherited;
end;

function TStrArrEnumerator.MoveNext: Boolean;
begin
  Inc(fIndex);
  Result := (fIndex < fList.Count);
end;

function TStrArrEnumerator.GetCurrent: string;
begin
  Result := fList[fIndex];
end;

// --- Examples
//function Has_O(const aStr: string): boolean;
//begin
//  Result := (Pos('o', aStr) > 0);
//end;
//
//procedure Test();
//var
//  Str, Str2: string;
//  SA, Filtered: TStrArr;
//begin
//  SA := TStrArr.Create();
//  try
//    SA.Add('one');
//    SA.Add('two');
//    SA.Add('three');
//    SA.Add('four');
//    SA.Add('five');
//    SA.Add('six');
//    SA.Add('seven');
//
//    SA.Shuffle().Sort();
//    Filtered := SA.Filter(@Has_O);
//    Filtered.Map(@UpperCase);
//
//    for Str in Filtered do
//      Str2 := Str;
//  finally
//    SA.Free();
//  end;
//end;
//
//begin
//  //Test();

end.

