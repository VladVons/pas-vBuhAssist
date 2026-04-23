// Created: 2026.03.14
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedFindZvit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ActnList, StdCtrls, Buttons, fpjson,
  uFMedFind, uMed, uHelper, uDmCommon, uConst;

type
  { TFMedFindZvit }
  TFMedFindZvit = class(TFMedFind)
    BitBtnRecommended: TBitBtn;
    DataSourceCur: TDataSource;
    DataSourcePrev: TDataSource;
    SQLQueryCur: TSQLQuery;
    SQLQueryCurCARDSENDSTT_NAME: TStringField;
    SQLQueryCurCARDSTATUS_NAME: TStringField;
    SQLQueryCurSTATUS2: TStringField;
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
    procedure BitBtnRecommendedClick(Sender: TObject);
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
  public
  end;

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
  Result := TStringList.Create().AddArray(Arr);
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

procedure TFMedFindZvit.ParentCalcFields(DataSet: TDataSet);
var
  Str, Status2: string;
  Idx: integer;
  FldXML, FldFJ, FldHZ: TField;
begin
  Status2 := DataSet.FieldByName('STATUS2').AsString;
  if (not Status2.IsEmpty()) then
  begin
    Idx := ComboBoxSendStatus.Items.IndexOfObject(TObject(Status2.ToInteger()));
    if (Idx = -1) then
      Str := 'Не відомий'
    else
      Str := ComboBoxSendStatus.Items[Idx];
    DataSet.FieldByName('CARDSENDSTT_NAME').AsString := Str;
  end;

  FldXML := DataSet.FieldByName('XMLVALS');
  FldFJ := DataSet.FieldByName('FJ');
  FldHZ := DataSet.FieldByName('HZ');
  if (DataSet.FieldByName('CHARCODE').IsNull) then
    FldHZ.AsString := 'Відсутній'
  else if (DataSet.FieldByName('CHARCODE').AsString.StartsWith('S')) then
    FldHZ.AsString := 'Звітний'
  else if (not FldXML.IsNull) and (not FldXML.AsString.IsEmpty()) then
    FldHZ.AsString := GetHzXml(FldXML.AsString)
  else if (not FldFJ.AsString.IsEmpty()) then
    FldHZ.AsString := GetHzStr(FldFJ.AsString);
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

procedure TFMedFindZvit.BitBtnRecommendedClick(Sender: TObject);
begin
  if (ComboBoxFirm.Text = cChooseAll) then
  begin
    Log('i', 'Не заповнено код ЄДРПОУ');
    Exit();
  end;

  if (ComboBoxMonth.Text = cChooseAll) then
  begin
    Log('i', 'Не заповнено період');
    Exit();
  end;

  ComboBoxDoc.ItemIndex := 0;
  ComboBoxSendStatus.ItemIndex := 0;
  BitBtnFindClick(nil);

  if (SQLQueryPrev.RecordCount > 0) then
    PageControl.ActivePage := TabSheetPrev
  else
    Log('i', Format('Не знайдено рекомендованих звітів по коду %s', [ComboBoxFirm.Text]));
end;

procedure TFMedFindZvit.FormCreate(Sender: TObject);
begin
  inherited;

  SQLTransaction.DataBase := DmCommon.IBConnection;

  SQLQueryCur.Database := DmCommon.IBConnection;
  SQLQueryCur.Transaction := SQLTransaction;
  DataSourceCur.DataSet := SQLQueryCur;
  DbGrid1.DataSource := DataSourceCur;

  SQLQueryPrev.Database := DmCommon.IBConnection;
  SQLQueryPrev.Transaction := SQLTransaction;
  DataSourcePrev.DataSet := SQLQueryPrev;
  DbGrid2.DataSource := DataSourcePrev;

  LoadJsonData();
  PageControl.ActivePage := TabSheetCur;
end;


end.

