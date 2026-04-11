// Created: 2026.04.07
// Author: Vladimir Vons <VladVons@gmail.com>

unit uDbList;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson,
  uHelper, uVarUtil;

type
  TDbRec = class
  private
    fData: TJSONArray;
    fFields: TJSONObject;

    function GetFieldByName(const aName: string): TJSONData;
    procedure SetFieldByName(const aName: string; aVal: TJSONData);
  public
    constructor Create(aData: TJSONArray; aFields: TJSONObject);

    function GetAsJSON(): TJSONObject;
    function GetFields(): TStringArray;
    procedure SetField(const aName: string; const aVal: string);
    procedure SetField(const aName: string; const aVal: Integer);
    procedure SetField(const aName: string; aVal: TJSONData);

    property Data: TJSONArray read fData write fData;
    property Fields[const aName: string]: TJSONData read GetFieldByName write SetFieldByName; default;
  end;

  { --- Iterator --- }
  TDbList = class;

  TDbListEnum = class
  private
    fList: TDbList;
    fIndex: Integer;
  public
    constructor Create(aList: TDbList);

    function MoveNext(): Boolean;
    function GetCurrent(): TDbRec;
    property Current: TDbRec read GetCurrent;
  end;

  { --- Main --- }
  TDbList = class
  private
    fJHead: TJSONObject;
    fJData: TJSONArray;
    fRec: TDbRec;
    fRecNo: Integer;

    procedure SetRecNo(aNo: Integer);
    function GetCount(): Integer;
  public
    constructor Create(aJHead, aJData: TJSONArray);
    constructor Create(aJObj: TJSONObject);
    destructor Destroy(); override;

    function Import(aJObj: TJSONObject): TDbList;
    function Export(): TJSONObject;
    function ExportStr(): string;
    function Print(const aFields, aCaptions: TStringArray): TStringList;
    function RecAdd(): TDbRec;
    function RecPop(aNo: Integer = -1): TDbRec;
    function GetEnumerator(): TDbListEnum;

    property Rec: TDbRec read fRec;
    property RecNo: Integer read fRecNo write SetRecNo;
    property Count: Integer read GetCount;
  end;

implementation

{ ================= TDbRec ================= }
constructor TDbRec.Create(aData: TJSONArray; aFields: TJSONObject);
begin
  fData := aData;
  fFields := aFields;
end;

function TDbRec.GetFieldByName(const aName: string): TJSONData;
var
  Idx: Integer;
begin
  Idx := fFields.Integers[aName];
  Result := fData.Items[Idx];
end;

procedure TDbRec.SetFieldByName(const aName: string; aVal: TJSONData);
var
  Idx: Integer;
begin
  Idx := fFields.Integers[aName];
  fData.Items[Idx] := aVal;
end;

function TDbRec.GetAsJSON(): TJSONObject;
var
  i: Integer;
  Key: string;
begin
  Result := TJSONObject.Create();
  for i := 0 to fFields.Count - 1 do
  begin
    Key := fFields.Names[i];
    Result.Add(Key, fData.Items[fFields.Integers[Key]].Clone());
  end;
end;

function TDbRec.GetFields(): TStringArray;
var
  i: Integer;
begin
  SetLength(Result, fFields.Count);
  for i := 0 to fFields.Count - 1 do
    Result[i] := fFields.Names[i];
end;

procedure TDbRec.SetField(const aName: string; const aVal: string);
begin
  Fields[aName] := TJSONString.Create(aVal);
end;

procedure TDbRec.SetField(const aName: string; const aVal: Integer);
begin
  Fields[aName] := TJSONIntegerNumber.Create(aVal);
end;

procedure TDbRec.SetField(const aName: string; aVal: TJSONData);
begin
  Fields[aName] := aVal;
end;

{ ================= Iterator ================= }
constructor TDbListEnum.Create(aList: TDbList);
begin
  fList := aList;
  fIndex := -1;
end;

function TDbListEnum.MoveNext(): Boolean;
begin
  Inc(fIndex);
  Result := (fIndex < fList.Count);
  if (Result) then
    fList.SetRecNo(fIndex);
end;

function TDbListEnum.GetCurrent(): TDbRec;
begin
  Result := fList.fRec;
end;

{ ================= TDbList ================= }
constructor TDbList.Create(aJHead, aJData: TJSONArray);
var
  i: Integer;
begin
  for i := 0 to aJHead.Count - 1 do
    fJHead.Add(aJHead.Strings[i], i);

  fJData := TJSONArray(aJData.Clone());

  if (fJData.Count > 0) then
    fRec := TDbRec.Create(TJSONArray(fJData.Items[0]), fJHead)
  else
    fRec := TDbRec.Create(TJSONArray.Create(), fJHead);

  fRecNo := 0;
end;

constructor TDbList.Create(aJObj: TJSONObject);
var
  i: Integer;
  JArr: TJSONArray;
begin
  fJHead := TJSONObject.Create();

  JArr := aJObj.Arrays['head'];
  if (JArr <> nil) then
    for i := 0 to JArr.Count - 1 do
      fJHead.Add(JArr.Strings[i], i);

  JArr := aJObj.Arrays['data'];
  if (JArr <> nil) then
    fJData := TJSONArray(JArr.Clone())
  else
    fJData := TJSONArray.Create();

  if (fJData.Count > 0) then
    fRec := TDbRec.Create(TJSONArray(fJData.Items[0]), fJHead)
  else
    fRec := TDbRec.Create(TJSONArray.Create(), fJHead);

  fRecNo := 0;
end;

destructor TDbList.Destroy();
begin
  FreeAndNil(fJHead);
  FreeAndNil(fJData);
  FreeAndNil(fRec);

  inherited Destroy();
end;

procedure TDbList.SetRecNo(aNo: Integer);
begin
  if (fJData.Count = 0) then
    fRecNo := 0
  else begin
    if (aNo < 0) then
      aNo := fJData.Count + aNo;

    if (aNo >= fJData.Count) then
      aNo := fJData.Count - 1;

    fRecNo := aNo;
    fRec.Data := TJSONArray(fJData.Items[fRecNo]);
  end;
end;

function TDbList.GetCount(): Integer;
begin
  Result := fJData.Count;
end;

function TDbList.Import(aJObj: TJSONObject): TDbList;
begin
  FreeAndNil(fJHead);
  FreeAndNil(fJData);

  Create(aJObj);
  Result := self;
end;

function TDbList.Export(): TJSONObject;
var
  i: integer;
  JArr: TJSONArray;
begin
  JArr := TJSONArray.Create();
  for i := 0 to fJHead.Count - 1 do
    JArr.Add(fJHead.Names[i]);

  Result := TJSONObject.Create();
  Result.Add('head', JArr);
  Result.Add('data', fJData.Clone());
end;

function TDbList.ExportStr(): string;
var
  JObj: TJSONObject;
begin
  JObj := Export();
  try
    Result := JObj.AsJSON;
  finally
    JObj.Free();
  end;
end;

function TDbList.Print(const aFields, aCaptions: TStringArray): TStringList;
var
  i: integer;
  Str, Caption: string;
  IsCaption: boolean;
  DbRec: TDbRec;
  SL: TStringList;
begin
  if (Length(aFields) = 0) then
    SL := fJHead.GetKeys()
  else
    SL := TStringList.Create().AddArray(aFields);

  IsCaption := (Length(aCaptions) > 0);
  Result := TStringList.Create();
  for DbRec in self do
  begin
    Str := '';
    for i := 0 to SL.Count - 1 do
    begin
      Caption := IIF(IsCaption, aCaptions[i], SL[i]);
      Str := Str + Format('%s: %s, ', [Caption, DbRec[SL[i]].AsString]);
    end;
    Result.Add(Str.TrimExt([',', ' ']));
  end;
end;

function TDbList.RecAdd(): TDbRec;
var
  Row: TJSONArray;
  i: Integer;
begin
  Row := TJSONArray.Create();
  for i := 0 to fJHead.Count - 1 do
    Row.Add(TJSONNull.Create());
  fJData.Add(Row);

  fRecNo := fJData.Count - 1;
  fRec.Data := Row;

  Result := fRec;
end;

function TDbList.RecPop(aNo: Integer): TDbRec;
var
  Row: TJSONArray;
begin
  if (aNo < 0) then
    aNo := fJData.Count + aNo;

  Row := TJSONArray(fJData.Extract(aNo));
  Result := TDbRec.Create(Row, fJHead);
end;

function TDbList.GetEnumerator(): TDbListEnum;
begin
  Result := TDbListEnum.Create(Self);
end;

end.
