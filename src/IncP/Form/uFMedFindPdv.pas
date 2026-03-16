// Created: 2026.03.15
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedFindPdv;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  uFMedFind, uMed, uVarHelper, uDmCommon;

type
  { TFMedFindPdv }
  TFMedFindPdv = class(TFMedFind)
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
    function  GetParentHideFiealds(): TObjectArray; override;
    function  GetParentDocsIncl(): TStringList; override;
  public

  end;

var
  FMedFindPdv: TFMedFindPdv;

implementation

{$R *.lfm}
{ TFMedFindPdv }

function TFMedFindPdv.GetParentQueryCur(): TSQLQuery;
begin
  Result := SQLQueryCur;
end;

function TFMedFindPdv.GetParentQueryPrev(): TSQLQuery;
begin
  Result := SQLQueryPrev;
end;

function TFMedFindPdv.GetParentTransaction(): TSQLTransaction;
begin
  Result := SQLTransaction;
end;

function TFMedFindPdv.GetParentDocsIncl(): TStringList;
begin
  Result := GetDocsFilter(ComboBoxDoc.Items);
end;

function TFMedFindPdv.GetParentHideFiealds(): TObjectArray;
begin
  Result := [
    SQLQueryCurINDTAXNUM,
    SQLQueryCurCARDSTATUS_NAME,
    SQLQueryCurPERDATE,
    SQLQueryCurFORM_NAME
  ];
end;

procedure TFMedFindPdv.SQLQueryCurCalcFields(DataSet: TDataSet);
begin
  SQLQueryGridCurCalcFields(DataSet);
end;

procedure TFMedFindPdv.FormCreate(Sender: TObject);
var
  SL: TStringList;
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

  SL := TStringList.Create().AddArray([
    'FJ-1201016=Податкова накладна',
    'FJ-1201216=Розрахунок коригування кількісних і вартісних показників',
    'FJ-1211001=Податкова накладна (експортне забезбечення',
    'FJ-1211201=Розрахунок коригування кількісних і вартісних показників (експ. заб.)'
  ]);
  SetComboBoxDoc(SL);
  SL.Free();

  SL := TStringList.Create().AddArray([
    '2=Вірний',
    '20=Очікується квитанція №1',
    '21=Не прийнято в ДПС',
    '110=Реєстрація зупинена',
    '114=Реєстрація скасовано'
  ]);
  SetComboBoxPair(ComboBoxSendStatus, SL);
  SL.Free();
end;


end.

