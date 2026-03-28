// Created: 2026.03.25
// Author: Vladimir Vons <VladVons@gmail.com>

unit uGrid;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, Grids, ValEdit, contnrs;

type

TStringGridEx = class(TStringGrid)
 private
   fColMap: TFPHashObjectList;
   function GetCol(const aField: string): Integer;
   function GetCell(const aField: string; aRow: Integer): string;
   procedure SetCell(const aField: string; aRow: Integer; const aValue: string);
 public
   constructor Create(aOwner: TComponent); override;
   destructor Destroy(); override;

   function DataToJson(): TJSONArray;
   procedure DataFromJson(aJArr: TJSONArray);
   procedure HeadFromJson(aJObj: TJSONObject);
   procedure DelRow(aIdx: Integer);
   function FindCol(const aType, aName: string): Integer;
   function IsRowEmpty(aRow: Integer): Boolean;
   property CellsN[const aField: string; aRow: Integer]: string read GetCell write SetCell;
 end;

function StringGrid_Clone(aStringGrid: TStringGrid; aOwner: TComponent): TStringGridEx;
function ValueList_ToJson(aGrid: TValueListEditor): TJSONArray;
procedure ValueList_FromJson(aGrid: TValueListEditor; aJArr: TJSONArray);

implementation

function StringGrid_Clone(aStringGrid: TStringGrid; aOwner: TComponent): TStringGridEx;
begin
  Result := TStringGridEx.Create(aOwner);
  Result.Parent := aStringGrid.Parent;
  Result.BoundsRect := aStringGrid.BoundsRect;
  Result.Align := aStringGrid.Align;
  Result.Options := aStringGrid.Options;
  Result.ColCount := aStringGrid.ColCount;
  Result.RowCount := aStringGrid.RowCount;
end;


constructor TStringGridEx.Create(aOwner: TComponent);
begin
  //inherited.Create(aOwner); //ToDo
  inherited;
  fColMap := TFPHashObjectList.Create(False);
end;

destructor TStringGridEx.Destroy();
begin
  FColMap.Free();
  inherited;
end;

function TStringGridEx.GetCol(const aField: string): Integer;
var
  Obj: TObject;
begin
  Obj := FColMap.Find(aField);
  if (Obj <> Nil) then
    Result := Integer(Obj)
  else
    Result := -1;
end;

function TStringGridEx.GetCell(const aField: string; aRow: Integer): string;
var
  Idx: Integer;
begin
  Idx := GetCol(aField);
  if (Idx >= 0) and (aRow >= 0) and (aRow < RowCount) then
    Result := Cells[Idx, aRow]
  else
    Result := '';
end;

procedure TStringGridEx.SetCell(const aField: string; aRow: Integer; const aValue: string);
var
  Idx: Integer;
begin
  Idx := GetCol(aField);
  if (Idx >= 0) and (aRow >= 0) and (aRow < RowCount) then
    Cells[Idx, aRow] := aValue;
end;

function TStringGridEx.FindCol(const aType, aName: string): Integer;
var
  i: Integer;
  JObj: TJSONObject;
begin
  for i := 0 to ColCount - 1 do
  begin
    JObj := TJSONObject(Objects[i, 0]);
    if (JObj <> Nil) and (JObj.Get(aType, '') = aName) then
      Exit(i);
  end;

  Result := -1;
end;

function TStringGridEx.IsRowEmpty(aRow: Integer): Boolean;
var
  i: Integer;
begin
  for i := 0 to ColCount - 1 do
    if (not Cells[i, aRow].IsEmpty()) then
      Exit(False);

  Result := True;
end;

function TStringGridEx.DataToJson(): TJSONArray;
var
  i, j: Integer;
  Str: string;
  JArr: TJSONArray;
  HasData: boolean;
begin
  Result := TJSONArray.Create();

  for i := FixedRows to RowCount - 1 do
  begin
    JArr := TJSONArray.Create();
    HasData := False;

    for j := 0 to ColCount - 1 do
    begin
      Str := Cells[j, i];
      JArr.Add(Str);
      HasData := HasData or (not Str.IsEmpty());
    end;

    if (HasData) then
      Result.Add(JArr)
    else
      JArr.Free();
  end;
end;

procedure TStringGridEx.DataFromJson(aJArr: TJSONArray);
var
  i, j: Integer;
  RowArr: TJSONArray;
begin
  if (aJArr = nil) or (aJArr.Count = 0) then
    Exit();

  ColCount := TJSONArray(aJArr[0]).Count;
  RowCount := aJArr.Count + FixedRows;

  for i := 0 to aJArr.Count - 1 do
  begin
    RowArr := TJSONArray(aJArr[i]);
    for j := 0 to RowArr.Count - 1 do
      Cells[j, i + FixedRows] := RowArr.Strings[j];
  end;
end;

procedure TStringGridEx.HeadFromJson(aJObj: TJSONObject);
var
  i: integer;
  Fields: TJSONArray;
  JObj: TJSONObject;
begin
  Options := Options + [goEditing];
  //aCtrl.OnSelectCell := @OnStringGridSelectCell;

  Fields := aJObj.Arrays['fields'];
  ColCount := Fields.Count;
  FixedCols := 0;
  for i := 0 to Fields.Count - 1 do
  begin
    JObj := Fields.Objects[i];
    Cells[i, 0] := JObj.Get('caption', '');
    ColWidths[i] := JObj.Get('width', 100);
    Objects[i, 0] := JObj;
    fColMap.Add(JObj.Get('name', ''), TObject(PtrInt(i)));
  end;
end;

procedure TStringGridEx.DelRow(aIdx: Integer);
var
  i: Integer;
begin
  if (aIdx < FixedRows) or (aIdx >= RowCount) then
    Exit();

  // Зсув рядків вгору
  for i := aIdx to RowCount - 2 do
    Rows[i].Assign(Rows[i + 1]);

  RowCount := RowCount - 1;
end;

//---
function ValueList_ToJson(aGrid: TValueListEditor): TJSONArray;
var
  i: Integer;
  Key, Val: string;
  JObj: TJSONObject;
begin
  Result := TJSONArray.Create();

  for i := 1 to aGrid.RowCount - 1 do // 0 — це заголовок
  begin
    Key := aGrid.Keys[i];
    Val := aGrid.Values[Key];
    if (Key.IsEmpty() and Val.IsEmpty()) then
      continue;

    JObj := TJSONObject.Create();
    JObj.Add('key', Key);
    JObj.Add('value', Val);

    Result.Add(JObj);
  end;
end;

procedure ValueList_FromJson(aGrid: TValueListEditor; aJArr: TJSONArray);
var
  i: Integer;
  JObj: TJSONObject;
  Key, Val: string;
begin
  if (aJArr = nil) or (aJArr.Count = 0) then
    Exit();

  aGrid.Strings.Clear;
  for i := 0 to aJArr.Count - 1 do
  begin
    JObj := TJSONObject(aJArr[i]);

    Key := JObj.Get('key', '');
    Val := JObj.Get('value', '');
    if (Key.IsEmpty() and Val.IsEmpty()) then
      continue;

    aGrid.InsertRow(Key, Val, True);
  end;
end;

initialization
  RegisterClass(TStringGridEx);

end.

