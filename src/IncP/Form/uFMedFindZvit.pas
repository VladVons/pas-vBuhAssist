// Created: 2026.03.14
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedFindZvit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, ExtCtrls, fpjson,
  uFMedFind, uMed, uVarHelper, uDmCommon;

type
  { TFMedFindZvit }
  TFMedFindZvit = class(TFMedFind)
    DataSourceCur: TDataSource;
    DataSourcePrev: TDataSource;
    SQLQueryCur: TSQLQuery;
    SQLQueryCurCARDSENDSTT_NAME: TStringField;
    SQLQueryCurCARDSTATUS_NAME: TStringField;
    SQLQueryCurCHARCODE: TStringField;
    SQLQueryCurDEPT: TStringField;
    SQLQueryCurEDRPOU: TStringField;
    SQLQueryCurFJ: TStringField;
    SQLQueryCurFORM_NAME: TStringField;
    SQLQueryCurHZ: TStringField;
    SQLQueryCurINDTAXNUM: TStringField;
    SQLQueryCurMODDATE: TDateTimeField;
    SQLQueryCurPERDATE: TDateField;
    SQLQueryCurPERDATE_STR: TStringField;
    SQLQueryCurPERTYPE: TIntegerField;
    SQLQueryCurSHORTNAME: TStringField;
    SQLQueryCurVAT: TStringField;
    SQLQueryCurXMLVALS: TBlobField;
    SQLQueryPrev: TSQLQuery;
    SQLQueryPrevCARDSENDSTT_NAME: TStringField;
    SQLQueryPrevCARDSTATUS_NAME: TStringField;
    SQLQueryPrevCHARCODE: TStringField;
    SQLQueryPrevEDRPOU: TStringField;
    SQLQueryPrevFORM_NAME: TStringField;
    SQLQueryPrevPERDATE: TDateField;
    SQLQueryPrevSHORTNAME: TStringField;
    SQLTransaction: TSQLTransaction;
    procedure FormCreate(Sender: TObject);
    procedure SQLQueryCurCalcFields(DataSet: TDataSet);
  protected
    function  GetParentQueryCur(): TSQLQuery; override;
    function  GetParentQueryPrev(): TSQLQuery; override;
    function  GetParentTransaction(): TSQLTransaction; override;
    function  GetParentHideFiealds(): TObjectArray ; override;
    function  GetParentDocsIncl(): TStringList; override;
    function  GetParentDocsExcl(): TStringList; override;
    procedure ParentQueryCurOpen(aQuery: TSQLQuery); override;
    procedure ParentCalcFields(DataSet: TDataSet); override;
    procedure QueryCharcodeNot(aQuery: TSQLQuery; aSL: TStringList);
  public

  end;

var
  FMedFindZvit: TFMedFindZvit;

implementation

{$R *.lfm}
{ TFMedFindZvit }

function TFMedFindZvit.GetParentQueryCur(): TSQLQuery;
begin
  Result := SQLQueryCur;
end;

function TFMedFindZvit.GetParentQueryPrev(): TSQLQuery;
begin
  Result := SQLQueryPrev;
end;

function TFMedFindZvit.GetParentTransaction(): TSQLTransaction;
begin
  Result := SQLTransaction;
end;

function TFMedFindZvit.GetParentDocsIncl(): TStringList;
begin
  Result := TStringList.Create();
end;

function TFMedFindZvit.GetParentDocsExcl(): TStringList;
var
  JData: TJSONData;
  Arr: TJSONArray;
begin
  //JData := fJData.FindPath('Filter/DocExcl'); Fuck
  Arr := TJSONObject(fJData.FindPath('Filter')).Arrays['DocExcl'];
  Result := TStringList.Create().AddJson(Arr);
end;

function TFMedFindZvit.GetParentHideFiealds(): TObjectArray;
begin
  Result := [
    SQLQueryCurINDTAXNUM,
    SQLQueryCurCARDSTATUS_NAME,
    SQLQueryCurPERDATE,
    SQLQueryCurFORM_NAME
  ];
end;

procedure TFMedFindZvit.SQLQueryCurCalcFields(DataSet: TDataSet);
begin
  SQLQueryGridCurCalcFields(DataSet);
end;

procedure TFMedFindZvit.QueryCharcodeNot(aQuery: TSQLQuery; aSL: TStringList);
var
  Macro, StrExcl: string;
  SL: TStringList;
begin
  Macro := '';
  if Assigned(aSL) and (aSL.Count > 0) then
  begin
    SL := TStringList.Create().AddExtDelim(aSL);
    StrExcl := QuotedStr(SL.GetJoin('|'));
    Macro := Format(' AND (FORM.CHARCODE NOT SIMILAR TO (%s))', [StrExcl]);
    SL.Free();
  end;
  aQuery.MacroByName('_COND_CHARCODE_NOT').Value := Macro;
end;

procedure TFMedFindZvit.ParentCalcFields(DataSet: TDataSet);
var
  FieldXML, FieldFJ, FieldHZ: TField;
begin
  FieldXML := DataSet.FieldByName('XMLVALS');
  FieldFJ := DataSet.FieldByName('FJ');
  FieldHZ := DataSet.FieldByName('HZ');

  if (DataSet.FieldByName('CHARCODE').IsNull) then
    FieldHZ.AsString := 'Відсутній'
  else if (DataSet.FieldByName('CHARCODE').AsString.StartsWith('S')) then
    FieldHZ.AsString := 'Звітний'
  else if (not FieldXML.IsNull) and (not FieldXML.AsString.IsEmpty()) then
    FieldHZ.AsString := GetHzXml(FieldXML.AsString)
  else if (not FieldFJ.AsString.IsEmpty()) then
    FieldHZ.AsString := GetHzStr(FieldFJ.AsString);
end;

procedure TFMedFindZvit.ParentQueryCurOpen(aQuery: TSQLQuery);
var
  Str, Macro: string;
  SL: TStringList;
begin
  SL := GetParentDocsExcl();
  QueryCharcodeNot(aQuery, SL);
  SL.Free();

  Macro := ', '''' AS FJ';
  if (Pos('FJ-0500110', ComboBoxDoc.Text) = 1) then
  begin
    Str := 'FJ0500106_MAIN';
    if (fTablesMain.IndexOf(Str) <> 0) then
    begin
      Macro := ', TFJ.HZ || ''-'' || TFJ.HZN || ''-'' || TFJ.HZU AS FJ';
      aQuery.MacroByName('_FROM_T2').Value :=
        Format(' LEFT JOIN %s TFJ ON TFJ.CARDCODE = CARD.CODE', [Str]);
    end;
  end;
  aQuery.MacroByName('_SELECT_T2').Value := Macro;

end;

procedure TFMedFindZvit.FormCreate(Sender: TObject);
begin
  inherited;

  SQLTransaction.DataBase := DmCommon.IBConnection;

  SQLQueryCur.Database := DmCommon.IBConnection;
  SQLQueryCur.Transaction := SQLTransaction;
  DataSourceCur.DataSet := SQLQueryCur;
  DbGridCur.DataSource := DataSourceCur;

  SQLQueryPrev.Database := DmCommon.IBConnection;
  SQLQueryPrev.Transaction := SQLTransaction;
  DataSourcePrev.DataSet := SQLQueryPrev;
  DbGridPrev.DataSource := DataSourcePrev;

  LoadJsonData();
end;


end.

