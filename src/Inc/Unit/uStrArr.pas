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
    function GetCount(): Integer;
    function GetItem(aIdx: Integer): string;
    procedure SetItem(aIdx: Integer; const aVal: string);
    procedure QuickSort(aL, aR: Integer);
  public
    procedure Add(const aStr: string);
    procedure Clear();
    procedure Delete(aIdx: Integer);
    procedure Insert(aIdx: Integer; const aStr: string);
    procedure Reverse();
    procedure Shuffle();
    procedure Sort();
    procedure Swap(aIdx1, aIdx2: Integer);

    function  GetEnumerator(): TStrArrEnumerator;
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

procedure TStrArr.Add(const aStr: string);
var
  Len: Integer;
begin
  Len := Length(fData);
  SetLength(fData, Len + 1);
  fData[Len] := aStr;
end;

procedure TStrArr.Insert(aIdx: Integer; const aStr: string);
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
end;

procedure TStrArr.Delete(aIdx: Integer);
var
  i, Len: Integer;
begin
  Len := Length(fData);
  if (aIdx < 0) or (aIdx >= Len) then Exit;

  for i := aIdx to Len - 2 do
    fData[i] := fData[i + 1];

  SetLength(fData, Len - 1);
end;

procedure TStrArr.Clear;
begin
  SetLength(fData, 0);
end;

procedure TStrArr.Swap(aIdx1, aIdx2: Integer);
var
  Str: string;
begin
  Str := fData[aIdx1];
  fData[aIdx1] := fData[aIdx2];
  fData[aIdx2] := Str;
end;

procedure TStrArr.Sort();
begin
  if (Length(fData) > 1) then
    QuickSort(0, High(fData));
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

procedure TStrArr.Reverse();
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
end;

procedure TStrArr.Shuffle();
var
  i, rnd: Integer;
begin
  for i := Count - 1 downto 1 do
  begin
    rnd := Random(i + 1);
    Swap(i, rnd);
  end;
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

end.

