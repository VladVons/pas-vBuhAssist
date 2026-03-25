// Created: 2026.03.25
// Author: Vladimir Vons <VladVons@gmail.com>

unit uGrid;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, fpjson, Grids;

function StringGridDataToJson(aGrid: TStringGrid): TJSONArray;
procedure StringGridDataFromJson(aGrid: TStringGrid; aJArr: TJSONArray);
procedure StringGridHeadFromJson(aGrid: TStringGrid; aJObj: TJSONObject);


implementation

function StringGridDataToJson(aGrid: TStringGrid): TJSONArray;
var
  i, j: Integer;
  Str: string;
  JArr: TJSONArray;
  HasData: boolean;
begin
  Result := TJSONArray.Create();

  for i := aGrid.FixedRows to aGrid.RowCount - 1 do
  begin
    JArr := TJSONArray.Create();
    HasData := False;
    for j := 0 to aGrid.ColCount - 1 do
    begin
      Str := aGrid.Cells[j, i];
      JArr.Add(Str);
      HasData := HasData or (not Str.IsEmpty());
    end;

    if (HasData) then
      Result.Add(JArr)
    else
      JArr.Free();
  end;
end;

procedure StringGridDataFromJson(aGrid: TStringGrid; aJArr: TJSONArray);
var
  i, j: Integer;
  RowArr: TJSONArray;
begin
  if (aJArr = nil) or (aJArr.Count = 0) then
    Exit();

  aGrid.ColCount := TJSONArray(aJArr[0]).Count;
  aGrid.RowCount := aJArr.Count + aGrid.FixedRows;

  for i := 0 to aJArr.Count - 1 do
  begin
    RowArr := TJSONArray(aJArr[i]);
    for j := 0 to RowArr.Count - 1 do
      aGrid.Cells[j, i + aGrid.FixedRows] := RowArr.Strings[j];
  end;
end;

procedure StringGridHeadFromJson(aGrid: TStringGrid; aJObj: TJSONObject);
var
  i: integer;
  Fields: TJSONArray;
  JObj: TJSONObject;
begin
  aGrid.Options := aGrid.Options + [goEditing];
  //aCtrl.OnSelectCell := @OnStringGridSelectCell;

  Fields := aJObj.Arrays['fields'];
  aGrid.ColCount := Fields.Count;
  aGrid.FixedCols := 0;
  for i := 0 to Fields.Count - 1 do
  begin
    JObj := Fields.Objects[i];
    aGrid.Cells[i, 0] := JObj.Get('caption', '');
    aGrid.ColWidths[i] := JObj.Get('width', 100);
  end;
end;


initialization
  //SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);

end.

