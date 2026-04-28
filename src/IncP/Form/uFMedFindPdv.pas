// Created: 2026.03.15
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedFindPdv;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, Buttons, Menus, fpjson, uDmCommon, uFMedFind, uFWizard,
  uWizardUser, uMed, uWinManager, uHelper, uConst, uSys, uSysVcl;

const
  cDirData = 'Data';
  cWizardMain = 'FWizard';

type
  { TFMedFindPdv }
  TFMedFindPdv = class(TFMedFind)
    BitBtnUnlock: TBitBtn;
    DataSourceCur: TDataSource;
    DataSourceOrg: TDataSource;
    DataSourcePrev: TDataSource;
    DataSourceFJ: TDataSource;
    PopupMenuWizards: TPopupMenu;
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
    SQLQueryFJA6_7: TFloatField;
    SQLQueryFJEDR_POK: TStringField;
    SQLQueryFJN3: TStringField;
    SQLQueryFJSEND_DPA_RN: TStringField;
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
    SQLQueryOrgKVED: TStringField;
    SQLQueryOrgLEADFIO: TStringField;
    SQLQueryOrgLEADINDTAX: TStringField;
    SQLQueryOrgORGLEGAL: TStringField;
    SQLQueryOrgPROPERTY: TStringField;
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
    procedure BitBtnUnlockClick(aSender: TBitBtn);
    procedure FormCreate(Sender: TObject);
    procedure SQLQueryCurCalcFields(DataSet: TDataSet);
  private
    procedure QueryFjOpen(aQuery: TSQLQuery; aJObj: TJSONObject);
    procedure QueryOrgOpen(aQuery: TSQLQuery; aJObj: TJSONObject);
    procedure InitPopupWizard();
    procedure OnPopupMenuWizardsClick(aSender: TObject);
    procedure RunWizard(aIdx: integer);
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
  aJObj.Add('T1RXXXXG8', FormatFloat('0.00', aQuery.FieldByName('A7_11').AsFloat));
  aJObj.Add('A6_7', FormatFloat('0.00', aQuery.FieldByName('A6_7').AsFloat));

  aJObj.Add('EDR_POK', aQuery.FieldByName('EDR_POK').AsString);
  aJObj.Add('SEND_DPA_RN', aQuery.FieldByName('SEND_DPA_RN').AsString);

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

  aJObj.Add('PROPERTY_NAME', aQuery.FieldByName('PROPERTY_NAME').AsString);
  aJObj.Add('ORGLEGAL_NAME', aQuery.FieldByName('ORGLEGAL_NAME').AsString);
  aJObj.Add('KVED_NAME', aQuery.FieldByName('KVED_NAME').AsString);

  //Log('i', ExpandSQL(aQuery));
  aQuery.Close();
end;

procedure TFMedFindPdv.RunWizard(aIdx: integer);
var
  Str, Dir: string;
  Form: TFWizard;
  JObj, JObjMed: TJSONObject;
  JArr: TJSONArray;
  SL: TStringList;
  TabSheet: TTabSheet;
  PerDate: TField;
begin
  if (not SQLQueryCur.Active) or (SQLQueryCur.RecordCount = 0) then
  begin
    Log('e', 'Не відібрано значення');
    Exit();
  end;

  Str := DBGrid1.DataSource.DataSet.FieldByName('EDRPOU').AsString;
  Log('i', Format('Розблокування ПН для %s', [Str]));
  PerDate := DBGrid1.DataSource.DataSet.FindField('PERDATE');
  if (IsDemo(Str, PerDate)) then
  begin
    Log('i', 'Не знайдено ліцензій');
    Exit();
  end;

  JObjMed := TJSONObject.Create();
  QueryFjOpen(SQLQueryFJ, JObjMed);
  QueryOrgOpen(SQLQueryOrg, JObjMed);

  Str := FormatDateTime('dd.mm.yyyy', Date());
  JObjMed.Add('_DATE', Str);
  JObjMed.Add('_DATE_WD', Str.Replace('.',''));
  JObjMed.Add('_YEAR', YearOf(Date()));
  JObjMed.Add('_MONTH', MonthOf(Date()));
  JObjMed.Add('_MONTH_U', GetMonthNameUa(MonthOf(Date())));
  JObjMed.Add('_DAY', DayOf(Date()));
  JObjMed.Add('_APP_NAME', cAppName);

  SL := JObjMed.GetList();
  Str := SL.GetJoin(LineEnding);
  JObjMed.Add('_VARS', Str);
  SL.Free();

  JArr := TJSONArray(ResourceLoadJson(cWizardMain));
  try
    JObj := JArr.Objects[aIdx];

    //Dir := ConcatPaths([GetAppConfigDir(false), cDirData, JObjMed.Get('HTIN', ''), JObjMed.Get('EDR_POK', '')]);
    Dir := ConcatPaths([cDirData, JObjMed.Get('HTIN', ''), JObjMed.Get('EDR_POK', '')]);
    if (not DirectoryExists(Dir)) then
       ForceDirectories(Dir);

    if (JObjMed.Get('HTIN', '') = '') then
    begin
      Log('e', 'Не заповнено код HTIN');
      Exit();
    end;

    Form := TFWizard(WinManager.Add(TFWizard));
    Form.SetHelper(TWizardUser.Create(Form));
    Form.Load(Dir, JObj, JObjMed);

    TabSheet := WinManager.GetPage(-1);
    TabSheet.Caption := JObj.Get('caption', '');
  finally
    JArr.Free();
    JObjMed.Free();
  end;
end;

procedure TFMedFindPdv.InitPopupWizard();
var
  i: integer;
  JObj: TJSONObject;
  JArr: TJSONArray;
  Item: TMenuItem;
begin
  JArr := TJSONArray(ResourceLoadJson(cWizardMain));
  try
    for i := 0 to JArr.Count - 1 do
    begin
      JObj := JArr.Objects[i];
      if (not JObj.Get('_enable', True)) then
        continue;

      Item := TMenuItem.Create(PopupMenuWizards);
      Item.Tag := i;
      Item.Caption := JObj.Get('caption', '');
      Item.OnClick := @OnPopupMenuWizardsClick;
      PopupMenuWizards.Items.Add(Item);
    end;
  finally
    JArr.Free();
  end;
end;

procedure TFMedFindPdv.BitBtnUnlockClick(aSender: TBitBtn);
var
  Pnt: TPoint;
begin
  Pnt := aSender.ClientToScreen(Point(0, aSender.Height));
  PopupMenuWizards.PopUp(Pnt.X, Pnt.Y);
end;

procedure TFMedFindPdv.OnPopupMenuWizardsClick(aSender: TObject);
begin
  RunWizard(TMenuItem(aSender).Tag);
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
  InitPopupWizard();
  BitBtnUnlock.Enabled := cCheckDevFile.FileExists();
end;


end.

