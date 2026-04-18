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
    fCount: Integer;
    function GetCount(): Integer; inline;
    function GetCapacity(): integer;
    function GetItem(aIdx: Integer): string; inline;
    function GetSize(): integer;
    procedure Grow();
    procedure IncCapacity(aVal: integer);
    procedure SetItem(aIdx: Integer; const aVal: string); inline;
    procedure QuickSort(aL, aR: Integer);
  public
    constructor Create();
    function Add(const aStr: string): TStrArr;
    function Add(const aArr: TStringArray): TStrArr;
    function Add(aStrArr: TStrArr): TStrArr;
    function Add(aSL: TStringList): TStrArr;
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
    function Sort(): TStrArr;
    function Swap(aIdx1, aIdx2: Integer): TStrArr;
    function ToArray(): TStringArray;

    function GetEnumerator(): TStrArrEnumerator;
    property Count: integer read GetCount;
    property Items[aIdx: Integer]: string read GetItem write SetItem; default;
  end;

implementation

// --- TStrArr
constructor TStrArr.Create();
begin
  inherited;
  fCount := 0;
end;

function TStrArr.GetEnumerator(): TStrArrEnumerator;
begin
  Result := TStrArrEnumerator.Create(Self);
end;

function TStrArr.GetCount: Integer;
begin
  Result := fCount;
end;

function TStrArr.GetItem(aIdx: Integer): string;
begin
  Result := fData[aIdx];
end;

procedure TStrArr.SetItem(aIdx: Integer; const aVal: string);
begin
  fData[aIdx] := aVal;
end;

procedure TStrArr.Grow();
const
  cLimit = 1000 * 1024;
var
  CurCap, NewCap: Integer;
begin
  CurCap := Length(fData);
  if (CurCap < cLimit) then
    NewCap := (CurCap + 2) * 2
  else
    NewCap := CurCap + cLimit;

  SetLength(fData, NewCap);
end;

function TStrArr.GetCapacity(): integer;
begin
  Result := Length(fData);
end;

procedure TStrArr.IncCapacity(aVal: integer);
begin
  SetLength(fData, Length(fData) + aVal);
end;

function TStrArr.GetSize(): integer;
var
  i: integer;
begin
  Result := 0;
  for i := 0 to fCount - 1 do
    Inc(Result, Length(fData[i]));
end;

function TStrArr.Add(const aStr: string): TStrArr;
begin
  if (fCount = Length(fData)) then
    Grow();

  fData[fCount] := aStr;
  Inc(fCount);

  Result := Self;
end;

function TStrArr.Add(const aArr: TStringArray): TStrArr;
var
  i: Integer;
begin
  IncCapacity(Length(aArr));

  for i := 0 to Length(aArr) - 1 do
  begin
    fData[fCount] := aArr[i];
    Inc(fCount);
  end;

  Result := self;
end;

function TStrArr.Add(aStrArr: TStrArr): TStrArr;
var
  i: Integer;
begin
  IncCapacity(aStrArr.Count);

  for i := 0 to aStrArr.Count - 1 do
  begin
    fData[fCount] := aStrArr.fData[i];
    Inc(fCount);
  end;

  Result := self;
end;

function TStrArr.Add(aSL: TStringList): TStrArr;
var
  i: Integer;
begin
  IncCapacity(aSL.Count);

  for i := 0 to aSL.Count - 1 do
  begin
    fData[fCount] := aSL[i];
    Inc(fCount);
  end;

  Result := self;
end;

function TStrArr.Any(aFunc: TFuncStrBool): Boolean;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if (aFunc(fData[i])) then
      Exit(true);

  Result := false;
end;

function TStrArr.All(aFunc: TFuncStrBool): Boolean;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if (not aFunc(fData[i])) then
      Exit(false);

  Result := true;
end;

function TStrArr.Insert(aIdx: Integer; const aStr: string): TStrArr;
var
  i: Integer;
begin
  if (aIdx < 0) or (aIdx > Count) then
    Exit(self);

  if (fCount = Length(fData)) then
      Grow();

  for i := Count downto aIdx + 1 do
    fData[i] := fData[i - 1];

  fData[aIdx] := aStr;
  Inc(fCount);

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
  i, Len, LenDelim: Integer;
begin
  LenDelim := Length(aDelim);
  Len := GetSize() + (LenDelim * (Count - 1));
  SetLength(Result, Len);

  Len := 1;
  for i := 0 to Count - 1 do
  begin
    if (i > 0) then
    begin
      Move(aDelim[1], Result[Len], LenDelim * SizeOf(Char));
      Inc(Len, LenDelim);
    end;

    Move(fData[i][1], Result[Len], Length(fData[i]) * SizeOf(Char));
    Inc(Len, Length(fData[i]));
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
  i: Integer;
begin
  if (aIdx < 0) or (aIdx >= Count) then
    Exit(Self);

  for i := aIdx to Count - 2 do
    fData[i] := fData[i + 1];

  Dec(fCount);
  Result := Self;
end;

function TStrArr.Clear(): TStrArr;
begin
  fCount := 0;
  SetLength(fData, 0);
  Result := self;
end;

function TStrArr.Swap(aIdx1, aIdx2: Integer): TStrArr;
var
  Str: string;
begin
  if (aIdx1 >= Count) or (aIdx2 >= Count) then
     Exit();

  Str := fData[aIdx1];
  fData[aIdx1] := fData[aIdx2];
  fData[aIdx2] := Str;

  Result := self;
end;

function TStrArr.ToArray(): TStringArray;
begin
  Result := Copy(fData, 0, Count);
end;

function TStrArr.Sort(): TStrArr;
begin
  if (Count > 1) then
    QuickSort(0, Count - 1);

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

  Dec(fCount);
  Result := fData[fCount];
end;

function TStrArr.Reverse(): TStrArr;
var
  i, j: Integer;
begin
  i := 0;
  j := Count - 1;

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
function Has_O(const aStr: string): boolean;
begin
  Result := (Pos('o', aStr) > 0);
end;

//procedure Test();
//var
//  i: integer;
//  Str, Str2: string;
//  SA, Filtered: TStrArr;
//begin
//  SA := TStrArr.Create();
//  try
//    for i := 0 to 1*1000 do
//    begin
//      SA.Add('one');
//      SA.Add('two');
//      SA.Add('three');
//      SA.Add('four');
//      SA.Add('five');
//      SA.Add('six');
//      SA.Add('seven');
//      SA.Add('eight');
//      SA.Add('nine');
//      SA.Add('zerro');
//    end;
//    Str2 := SA.Join(', ');
//
//    SA.Shuffle().Sort();
//    Str2 := SA.Join(', ');
//
//    SA.Reverse();
//    Str2 := SA.Join(', ');
//
//    Filtered := SA.Filter(@Has_O);
//    Filtered.Map(@UpperCase);
//    for Str in Filtered do
//      Str2 := Str;
//
//  finally
//    SA.Free();
//  end;
//end;
//
//begin
//  Test();

end.

