// Created: 2026.03.14
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedFindZvit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, ExtCtrls,
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
  protected
    function  GetParentQueryCur(): TSQLQuery; override;
    function  GetParentQueryPrev(): TSQLQuery; override;
    function  GetParentTransaction(): TSQLTransaction; override;
    function  GetParentHideFiealds(): TObjectArray ; override;
    function  GetParentDocsIncl(): TStringList; override;
    function  GetParentDocsExcl(): TStringArray; override;
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

function TFMedFindZvit.GetParentDocsExcl(): TStringArray;
begin
  Result := cArrExcl;
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

procedure TFMedFindZvit.FormCreate(Sender: TObject);
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
    'FJ-0200126=Податкова декларація з податку на додану вартість',
    'FJ-0500110=Податковий розрахунок сум доходу ... ЄСВ',
    'FJ-0209513=Податкова декларація акцизного податку'
  ]);
  SetComboBoxDoc(SL);
  SL.Free();
end;


end.

