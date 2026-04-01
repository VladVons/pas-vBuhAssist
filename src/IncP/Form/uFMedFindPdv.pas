// Created: 2026.03.15
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedFindPdv;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons, fpjson, Math,
  uDmCommon, uFMedFind, uFWizard, uMed, uWinManager, uHelper, uConst, uSys, uQuery;

type
  { TFMedFindPdv }
  TFMedFindPdv = class(TFMedFind)
    BitBtnUnlock: TBitBtn;
    DataSourceCur: TDataSource;
    DataSourceOrg: TDataSource;
    DataSourcePrev: TDataSource;
    DataSourceFJ: TDataSource;
    SQLQueryCur: TSQLQuery;
    SQLQueryCurCARDSENDSTT_NAME: TStringField;
    SQLQueryCurCARDSTATUS_NAME: TStringField;
    SQLQueryCurCARD_CODE: TLongintField;
    SQLQueryCurCHARCODE: TStringField;
    SQLQueryCurDEPT: TStringField;
    SQLQueryCurEDRPOU: TStringField;
    SQLQueryCurFORM_NAME: TStringField;
    SQLQueryCurHZ: TStringField;
    SQLQueryCurINDTAXNUM: TStringField;
    SQLQueryCurMODDATE: TDateTimeField;
    SQLQueryCurPERDATE: TDateField;
    SQLQueryCurPERDATE_STR: TStringField;
    SQLQueryCurPERTYPE: TIntegerField;
    SQLQueryCurSHORTNAME: TStringField;
    SQLQueryCurVAT: TStringField;
    SQLQueryOrg: TSQLQuery;
    SQLQueryFJA7_11: TCurrencyField;
    SQLQueryFJFIRM_EDRPOU: TStringField;
    SQLQueryFJFIRM_NAME: TStringField;
    SQLQueryFJN10: TStringField;
    SQLQueryFJN11: TDateField;
    SQLQueryFJN2_1: TStringField;
    SQLQueryFJN4: TStringField;
    SQLQueryOrgHBTAXINSP_NAME: TStringField;
    SQLQueryOrgLEADFIO: TStringField;
    SQLQueryOrgLEADINDTAX: TStringField;
    SQLQueryOrgTAXINSPNUM: TStringField;
    SQLQueryPrev: TSQLQuery;
    SQLQueryFJ: TSQLQuery;
    SQLQueryPrevCARDSENDSTT_NAME: TStringField;
    SQLQueryPrevCARDSTATUS_NAME: TStringField;
    SQLQueryPrevCHARCODE: TStringField;
    SQLQueryPrevEDRPOU: TStringField;
    SQLQueryPrevFORM_NAME: TStringField;
    SQLQueryPrevPERDATE: TDateField;
    SQLQueryPrevSHORTNAME: TStringField;
    SQLTransaction: TSQLTransaction;
    procedure BitBtnUnlockClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SQLQueryCurCalcFields(DataSet: TDataSet);
  private
    procedure QueryFjOpen(aQuery: TSQLQuery; aJObj: TJSONObject);
    procedure QueryOrgOpen(aQuery: TSQLQuery; aJObj: TJSONObject);
  protected
    function  GetParentQueryCur(): TSQLQuery; override;
    function  GetParentQueryPrev(): TSQLQuery; override;
    function  GetParentTransaction(): TSQLTransaction; override;
    function  GetParentHideFiealds(): TObjectArray; override;
    function  GetParentDocsIncl(): TStringList; override;
  public
  end;

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

procedure TFMedFindPdv.QueryFjOpen(aQuery: TSQLQuery; aJObj: TJSONObject);
var
  Code: integer;
  Dbl: Double;
begin
  Code := SQLQueryCur.FieldByName('CARD_CODE').AsInteger;
  aQuery.ParamByName('_CARDCODE').AsInteger := Code;
  aQuery.Open();

  aJObj.Add('HNAME', aQuery.FieldByName('FIRM_NAME').AsString);
  aJObj.Add('HTIN', aQuery.FieldByName('FIRM_EDRPOU').AsString);
  aJObj.Add('TIN', aQuery.FieldByName('FIRM_EDRPOU').AsString);
  //aJObj.Add('HBOS', aQuery.FieldByName('N10').AsString);

  aJObj.Add('T1RXXXXG2D', aQuery.FieldByName('N11').AsString);
  aJObj.Add('T1RXXXXG31', aQuery.FieldByName('N2_1').AsString);
  aJObj.Add('T1RXXXXG6S', aQuery.FieldByName('N4').AsString);
  aJObj.Add('T1RXXXXG7S', aQuery.FieldByName('FIRM_NAME').AsString);
  Dbl := RoundTo(aQuery.FieldByName('A7_11').AsFloat, -2);
  aJObj.Add('T1RXXXXG8', FormatFloat('0.00', Dbl));

  Log('i', ExpandSQL(aQuery));
  aQuery.Close();
end;

procedure TFMedFindPdv.QueryOrgOpen(aQuery: TSQLQuery; aJObj: TJSONObject);
var
  Code: string;
begin
  Code := SQLQueryCur.FieldByName('EDRPOU').AsString;
  aQuery.ParamByName('_EDRPOU').AsString := Code;
  aQuery.Open();

  Code := aQuery.FieldByName('TAXINSPNUM').AsString;
  aJObj.Add('C_STI_ORIG', Code);
  aJObj.Add('HKSTI', Code);
  aJObj.Add('C_REG', Code.Left(2));
  aJObj.Add('C_RAJ', Code.Right(2));

  aJObj.Add('HSTI', aQuery.FieldByName('HBTAXINSP_NAME').AsString);
  aJObj.Add('HKBOS', aQuery.FieldByName('LEADINDTAX').AsString);
  aJObj.Add('HBOS', aQuery.FieldByName('LEADFIO').AsString);

  Log('i', ExpandSQL(aQuery));
  aQuery.Close();
end;

procedure TFMedFindPdv.BitBtnUnlockClick(Sender: TObject);
var
  Str: string;
  Form: TFWizard;
  JObj: TJSONObject;
  SL: TStringList;
begin
  if (not SQLQueryCur.Active) then
  begin
    Log('e', 'Не відібрано значення');
    Exit();
  end;

  JObj := TJSONObject.Create();
  QueryFjOpen(SQLQueryFJ, JObj);
  QueryOrgOpen(SQLQueryOrg, JObj);

  JObj.Add('DATE', FormatDateTime('dd.mm.yyyy', Date()));
  JObj.Add('YEAR', YearOf(Date()));
  JObj.Add('MONTH', MonthOf(Date()));
  JObj.Add('MONTHU', GetMonthNameUa(MonthOf(Date())));
  JObj.Add('DAY', DayOf(Date()));
  JObj.Add('APP_NAME', cAppName);

  SL := JObj.GetList();
  Str := SL.GetJoin(LineEnding);
  JObj.Add('VARS', Str);
  SL.Free();

  Form := TFWizard(WinManager.Add(TFWizard));
  Form.LoadAll('FWizardPdvs', JObj);
  //Form.SaveXml('J1360102', JObj);
  //Form.SaveXml('J1312603', JObj);

  //JObj.Free();
end;

procedure TFMedFindPdv.FormCreate(Sender: TObject);
begin
  inherited;

  SQLTransaction.DataBase := DmCommon.IBConnection;

  SQLQueryCur.Database := DmCommon.IBConnection;
  SQLQueryCur.Transaction := SQLTransaction;
  DataSourceCur.DataSet := SQLQueryCur;
  DbGridCur.DataSource := DataSourceCur;

  //SQLQueryPrev.Database := DmCommon.IBConnection;
  //SQLQueryPrev.Transaction := SQLTransaction;
  //DataSourcePrev.DataSet := SQLQueryPrev;
  //DbGridPrev.DataSource := DataSourcePrev;

  //SQLQueryFJ.Database := DmCommon.IBConnection;
  //SQLQueryFJ.Transaction := SQLTransaction;
  //DataSourceFJ.DataSet := SQLQueryFJ;

  LoadJsonData();
end;


end.

