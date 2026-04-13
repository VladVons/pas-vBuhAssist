// Created: 2026.03.25
// Author: Vladimir Vons <VladVons@gmail.com>

unit uExGrid;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Grids, Controls, StdCtrls, Dialogs, ValEdit, contnrs, fpjson, fgl,
  uDbList;

type
 TStringIntMap = specialize TFPGMap<string, Integer>;
 TOnOpenFileDialog = function (const aFile: string): string of object;

 TStringGridEx = class(TStringGrid)
 private
   fColMap: TStringIntMap;
   fComboBox: TComboBox;
   fOpenDialog: TOpenDialog;
   fMaxRows: integer;

   function GetCol(const aField: string): Integer;
   function GetCell(const aField: string; aRow: Integer): string;
   function GetColInfo(aCol: integer; const aProp: string): string;
   procedure SetCell(const aField: string; aRow: Integer; const aValue: string);
   procedure DoComboBoxEditingDone(aSender: TObject);
   procedure DoSelectEditor(aSender: TObject; aCol,  aRow: Integer; var aEditor: TWinControl);
   procedure DoDrawCell(aSender: TObject; aCol, aRow: Integer; aRect: TRect; State: TGridDrawState);
   procedure DoMouseDown(aSender: TObject; aButton: TMouseButton; aShift: TShiftState; aX, aY: Integer);
   procedure DoHeaderSized(aSender: TObject;  aIsColumn: Boolean; aIndex: Integer);
   procedure DoSelectCell(aSender: TObject; aCol, aRow: Integer; var aCanSelect: Boolean);
procedure ImportInternal(aJObj: TJSONObject; aStart: integer);
 public
   OnOpenFileDialog: TOnOpenFileDialog;
   constructor Create(aOwner: TComponent); override;
   destructor Destroy(); override;

   function Export(): TJSONObject;
   function ExportAsDbList(): TDbList;
   procedure Import(aJObj: TJSONObject);
   procedure ImportAdd(aJObj: TJSONObject);
   function GetMaxRows(): integer;
   function GetColType(aCol: integer): string;
   function GetColName(aCol: integer): string;
   procedure LoadHeadFromJson(aJObj: TJSONObject);
   procedure DelRow(aIdx: Integer);
   procedure RowFill();
   function TableCheck(): TPoint;
   function RowCheck(aRow: integer): integer;
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
  fColMap := TStringIntMap.Create();
  fColMap.Sorted := True;

  Options := Options + [goEditing];
  OnSelectEditor := @DoSelectEditor;
  OnDrawCell := @DoDrawCell;
  OnMouseDown := @DoMouseDown;
  OnHeaderSized := @DoHeaderSized;
  //OnSelectCell := @DoSelectCell;

  fComboBox := TComboBox.Create(self);
  fComboBox.ReadOnly := True;
  fComboBox.OnEditingDone := @DoComboBoxEditingDone;

  fOpenDialog := TOpenDialog.Create(self);
  fOpenDialog.Filter := 'Files (*.pdf;*.jpg;*.jpeg)|*.pdf;*.jpg;*.jpeg';
end;

destructor TStringGridEx.Destroy();
begin
  FreeAndNil(FColMap);
  FreeAndNil(fComboBox);
  FreeAndNil(fOpenDialog);
  inherited;
end;

function TStringGridEx.GetColInfo(aCol: integer; const aProp: string): string;
var
  JObj: TJSONObject;
begin
  JObj := TJSONObject(Objects[aCol, 0]);
  if (JObj = nil) then
    Result := ''
  else
    Result := JObj.Get(aProp, '');
end;

function TStringGridEx.GetColName(aCol: integer): string;
begin
  Result := GetColInfo(aCol, 'name');
end;

function TStringGridEx.GetColType(aCol: integer): string;
begin
  Result := GetColInfo(aCol, 'type');
end;

function TStringGridEx.GetMaxRows(): integer;
begin
  Result := fMaxRows;
end;

function TStringGridEx.GetCol(const aField: string): Integer;
begin
  Result := fColMap.IndexOf(aField);
  if (Result <> -1) then
    Result := fColMap.Data[Result];
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

procedure TStringGridEx.RowFill();
var
  i: Integer;
  Str: string;
  JObj: TJSONObject;
begin
  for i := 0 to ColCount - 1 do
  begin
    JObj := TJSONObject(Objects[i, 0]);
    if (JObj <> Nil) then
    begin
      Str := JObj.Get('_default', '');
      if (not Str.IsEmpty()) then
        Cells[i, Row] := Str;
    end;
  end;
end;

function TStringGridEx.TableCheck(): TPoint;
var
  i, ColErr: Integer;
begin
  for i := 1 to RowCount - 1 do
  begin
    ColErr := RowCheck(i);
    if (ColErr <> -1) then
    begin
      Result.X := ColErr;
      Result.Y := i;
      Exit();
    end;
  end;

  Result.X := -1;
  Result.Y := -1;
end;


function TStringGridEx.RowCheck(aRow: integer): integer;
var
  i: Integer;
  JObj: TJSONObject;
begin
  for i := 0 to ColCount - 1 do
  begin
    JObj := TJSONObject(Objects[i, 0]);
    if (JObj <> Nil) and (JObj.Get('required', false)) then
      if (Cells[i, aRow].IsEmpty()) then
        Exit(i);
  end;

  Result := -1;
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

function TStringGridEx.Export(): TJSONObject;
var
  i, j: Integer;
  Str: string;
  JArr, JArrRows: TJSONArray;
  JObj: TJSONObject;
  HasData: boolean;
begin
  JArrRows := TJSONArray.Create();
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
      JArrRows.Add(JArr)
    else
      JArr.Free();
  end;

  JArr := TJSONArray.Create();
  for i := 0 to ColCount - 1 do
  begin
    JObj := TJSONObject(Objects[i, 0]);
    JArr.Add(JObj.Get('name', ''));
  end;

  Result := TJSONObject.Create();
  Result.Add('head', JArr);
  Result.Add('data', JArrRows);
end;

function TStringGridEx.ExportAsDbList(): TDbList;
var
  JObj: TJSONObject;
begin
  JObj := Export();
  Result := TDbList.Create(JObj);
  JObj.Free();
end;

procedure TStringGridEx.ImportInternal(aJObj: TJSONObject; aStart: integer);
var
  i: integer;
  Field: string;
  Fields: TStringArray;
  DBL: TDbList;
  DbRec: TDbRec;
begin
  if (aJObj = nil) then
    Exit();

  DBL := TDbList.Create(aJObj);
  try
    if (DBL.Count = 0) then
      Exit();

    RowCount := aStart + FixedRows + DBL.Count;
    Fields := DBL.Rec.GetFields();
    for DbRec in DBL do
      for i := 0 to Length(Fields) -1 do
      begin
        Field := Fields[i];
        CellsN[Field, aStart + FixedRows + DBL.RecNo] := DbRec.Fields[Field].AsString;
      end;
  finally
    DBL.Free();
  end;
end;

procedure TStringGridEx.Import(aJObj: TJSONObject);
begin
  ImportInternal(aJObj, 0);
end;

procedure TStringGridEx.ImportAdd(aJObj: TJSONObject);
begin
  ImportInternal(aJObj, RowCount);
end;

procedure TStringGridEx.LoadHeadFromJson(aJObj: TJSONObject);
var
  i: integer;
  Field: string;
  JObj: TJSONObject;
  JFields: TJSONArray;
begin
  Options := Options + [goEditing];
  //aCtrl.OnSelectCell := @OnStringGridSelectCell;

  fMaxRows := aJObj.Get('_maxrows', -1);

  JFields := aJObj.Arrays['fields'];
  ColCount := JFields.Count;
  FixedCols := 0;
  for i := 0 to JFields.Count - 1 do
  begin
    JObj := JFields.Objects[i];
    Cells[i, 0] := JObj.Get('caption', '');
    ColWidths[i] := JObj.Get('width', 100);
    Objects[i, 0] := JObj;
    Field := JObj.Get('name', '');
    fColMap.Add(Field, i);
  end;

  JObj := TJSONObject(aJObj.Find('_data'));
  Import(JObj);
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

procedure TStringGridEx.DoComboBoxEditingDone(aSender: TObject);
begin
  Cells[Col, Row] := TComboBox(aSender).Text;
end;

procedure TStringGridEx.DoHeaderSized(aSender: TObject;  aIsColumn: Boolean; aIndex: Integer);
begin
  if (aIsColumn and (GetColType(aIndex) = 'list')) then
    fComboBox.BoundsRect := CellRect(aIndex, Row);
end;

procedure TStringGridEx.DoSelectCell(aSender: TObject; aCol, aRow: Integer; var aCanSelect: Boolean);
var
  ErrCol: Integer;
begin
  ErrCol := RowCheck(Row);
  if (ErrCol <> -1) then
  begin
    //CanSelect := False;
    Col := ErrCol;
    SetFocus();
  end;
end;

procedure TStringGridEx.DoSelectEditor(aSender: TObject; aCol,  aRow: Integer; var aEditor: TWinControl);
var
  Typ: string;
  i: integer;
  JArr: TJSONArray;
  JObj: TJSONObject;
begin
  Typ := GetColTYpe(aCol);
  if (Typ.IsEmpty()) then
    Exit();

  JObj := TJSONObject(Objects[aCol, 0]);
  if (Typ = 'list') then
  begin
    fComboBox.Items.Clear();
    fComboBox.Parent := self;
    fComboBox.BoundsRect := CellRect(aCol, aRow);
    fComboBox.Text := Cells[aCol, aRow];
    aEditor := fComboBox;

    JArr := JObj.Arrays['items'];
    for i := 0 to JArr.Count - 1 do
      fComboBox.Items.Add(JArr[i].AsString);
  end;
end;

procedure TStringGridEx.DoDrawCell(aSender: TObject; aCol, aRow: Integer; aRect: TRect; State: TGridDrawState);
begin
  if (aRow = 0) then
    Exit();

  if (GetColType(aCol) = 'file') then
    Canvas.TextOut(aRect.Right - 25, aRect.Top + 4, '***');
end;

procedure TStringGridEx.DoMouseDown(aSender: TObject; aButton: TMouseButton; aShift: TShiftState; aX, aY: Integer);
var
  ACol, ARow: Longint;
  CRect: TRect;
begin
  MouseToCell(aX, aY, aCol, aRow);
  if (ARow = 0) then
    Exit();

  if (GetColType(ACol) = 'file') then
  begin
    CRect := CellRect(ACol, ARow);
    if (aX >= CRect.Right - 25) then  // клік саме на кнопці
      if (fOpenDialog.Execute()) then
        if (Assigned(OnOpenFileDialog)) then
          Cells[ACol, ARow] := OnOpenFileDialog(fOpenDialog.FileName);
  end;
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

