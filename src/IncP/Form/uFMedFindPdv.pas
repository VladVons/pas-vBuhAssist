// Created: 2026.03.15
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedFindPdv;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons, fpjson, Math,
  uDmCommon, uFMedFind, uFWizard, uWizardUser, uMed, uWinManager, uHelper, uConst, uSys, uQuery;

const
  cDirData = 'Data\12345';

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
    SQLQueryFJEDR_POK: TStringField;
    SQLQueryFJN3: TStringField;
    SQLQueryOrg: TSQLQuery;
    SQLQueryFJA7_11: TCurrencyField;
    SQLQueryFJFIRM_EDRPOU: TStringField;
    SQLQueryFJFIRM_NAME: TStringField;
    SQLQueryFJN10: TStringField;
    SQLQueryFJN11: TDateField;
    SQLQueryFJN2_1: TStringField;
    SQLQueryFJN4: TStringField;
    SQLQueryOrgEDRPOU: TStringField;
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
  aJObj.Add('N3', aQuery.FieldByName('N3').AsString);
  aJObj.Add('T1RXXXXG2D', aQuery.FieldByName('N11').AsString);
  aJObj.Add('T1RXXXXG31', aQuery.FieldByName('N2_1').AsString);
  aJObj.Add('T1RXXXXG6S', aQuery.FieldByName('N4').AsString);
  aJObj.Add('T1RXXXXG7S', aQuery.FieldByName('FIRM_NAME').AsString);
  Dbl := RoundTo(aQuery.FieldByName('A7_11').AsFloat, -2);
  aJObj.Add('T1RXXXXG8', FormatFloat('0.00', Dbl));

  aJObj.Add('EDR_POK', aQuery.FieldByName('EDR_POK').AsString);

  //Log('i', ExpandSQL(aQuery));
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

  // ToDo
  aJObj.Add('H01', '1');
  aJObj.Add('FILLDOC', '01.01.2026');
  aJObj.Add('NAMEDOC', '123');
  aJObj.Add('NUMDOC', '333');
  aJObj.Add('R001G10', 1);
  //aJObj.Add('R01G1B', EncodeStringBase64('Hello Base64'));
  aJObj.Add('HNUM_1', 1);
  aJObj.Add('HNUM_2', 1);
  aJObj.Add('R01G1S_1', 'пояснення');
  aJObj.Add('R01G1S_2', 'рахунок');
  aJObj.Add('T1RXXXXG5', '999');

  //Log('i', ExpandSQL(aQuery));
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

  Str := FormatDateTime('dd.mm.yyyy', Date());
  JObj.Add('_DATE', Str);
  JObj.Add('_DATE_WD', Str.Replace('.',''));
  JObj.Add('_YEAR', YearOf(Date()));
  JObj.Add('_MONTH', MonthOf(Date()));
  JObj.Add('_MONTH_U', GetMonthNameUa(MonthOf(Date())));
  JObj.Add('_DAY', DayOf(Date()));
  JObj.Add('_APP_NAME', cAppName);

  SL := JObj.GetList();
  Str := SL.GetJoin(LineEnding);
  JObj.Add('_VARS', Str);
  SL.Free();

  Str := ConcatPaths(['Data', JObj.Get('HTIN', ''), JObj.Get('EDR_POK', '')]);
  Form := TFWizard(WinManager.Add(TFWizard));
  Form.SetHelper(TWizardUser.Create(Form));
  Form.Load('FWizardPdvs', Str, JObj);

  JObj.Free();
end;

procedure TFMedFindPdv.FormCreate(Sender: TObject);
begin
  inherited;

  SQLTransaction.DataBase := DmCommon.IBConnection;

  SQLQueryCur.Database := DmCommon.IBConnection;
  SQLQueryCur.Transaction := SQLTransaction;
  DataSourceCur.DataSet := SQLQueryCur;
  DbGrid1.DataSource := DataSourceCur;

  //SQLQueryPrev.Database := DmCommon.IBConnection;
  //SQLQueryPrev.Transaction := SQLTransaction;
  //DataSourcePrev.DataSet := SQLQueryPrev;
  //DBGrid2.DataSource := DataSourcePrev;

  //SQLQueryFJ.Database := DmCommon.IBConnection;
  //SQLQueryFJ.Transaction := SQLTransaction;
  //DataSourceFJ.DataSet := SQLQueryFJ;

  LoadJsonData();
  BitBtnUnlock.Enabled := 'res\json\FMedFindPdv.json'.FileExists();
end;


end.

