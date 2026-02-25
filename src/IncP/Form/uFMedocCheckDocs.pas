// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils, SQLDB, Forms, Graphics, StdCtrls,
  DBGrids, Grids, ExtCtrls, Buttons, Menus, LR_Class, LR_DBSet, LR_PGrid,
  LR_Desgn, DB, fpjson, Math, uFBase, uSys, uLog, uLicence, uWinReg, uSettings,
  uStateStore, uQuery, uMedoc, uDmCommon, uProtectTimer, uConst;

type

  { TFMedocCheckDocs }
  TFMedocCheckDocs = class(TFBase)
    ButtonExec: TButton;
    ButtonActivation: TButton;
    ButtonPrint: TButton;
    ButtonRunMedoc: TButton;
    ComboBoxDoc: TComboBox;
    ComboBoxFirm: TComboBox;
    ComboBoxMonth: TComboBox;
    ComboBoxPath: TComboBox;
    ComboBoxYear: TComboBox;
    DataSourceGrid: TDataSource;
    DbGrid: TDBGrid;
    frDBDataSet1: TfrDBDataSet;
    FrPrintGrid1: TFrPrintGrid;
    frReport1: TfrReport;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    MenuItemOrder: TMenuItem;
    MenuItemRefresh: TMenuItem;
    Panel1: TPanel;
    PopupMenuActivation: TPopupMenu;
    SQLQueryGrid: TSQLQuery;
    SQLQueryGridCARDSENDSTT_NAME: TStringField;
    SQLQueryGridCHARCODE: TStringField;
    SQLQueryGridDEPT: TStringField;
    SQLQueryGridEDRPOU: TStringField;
    SQLQueryGridHZ: TStringField;
    SQLQueryGridINDTAXNUM: TStringField;
    SQLQueryGridMODDATE: TDateTimeField;
    SQLQueryGridPERDATE: TDateField;
    SQLQueryGridPERDATE_STR: TStringField;	
    SQLQueryGridSHORTNAME: TStringField;
    SQLQueryGridCARDSTATUS_NAME: TStringField;
    SQLQueryGridVAT: TStringField;
    SQLQueryGridXMLVALS: TBlobField;
    SQLQueryGridFJ: TStringField;
    procedure ButtonExecClick(Sender: TObject);
    procedure ButtonActivationClick(Sender: TObject);
    procedure ButtonPrintClick(Sender: TObject);
    procedure ButtonRunMedocClick(Sender: TObject);
    procedure ComboBoxPathChange(Sender: TObject);
    procedure ComboBoxYearDropDown(Sender: TObject);
    procedure DbGridDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: integer; Column: TColumn; State: TGridDrawState);
    procedure DbGridTitleClick(Column: TColumn);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure frReport1GetValue(const aParName: string; var aParValue: Variant);
    procedure MenuItemOrderClick(Sender: TObject);
    procedure MenuItemRefreshClick(Sender: TObject);
    procedure SQLQueryGridCalcFields(DataSet: TDataSet);
  private
    fSortField: string;
    fSortAsc: boolean;
    fJMedocApp: TJSONArray;
    fFirmCodesLicensed, fTablesMain, fDemoFields: TStringList;
    fColorYelow: TColor;
    procedure SetComboBoxToCurrentMonth(aComboBox: TComboBox);
    procedure SetComboBoxToYear(aComboBox: TComboBox; aYear: integer = 0);
    procedure SetComboBoxDoc();
    procedure QueryOpen();
    procedure SetEmbededPath(aIdx: integer);
    procedure ConnectToDb();
    function GetCurPathObj(): TJSONObject;
  public

  end;

var
  FMedocCheckDocs: TFMedocCheckDocs;

implementation

{$R *.lfm}
{$I uFMedocCheckDocs_Comp.inc}

{ TFMedocCheckDocs }

procedure TFMedocCheckDocs.SetEmbededPath(aIdx: integer);
var
  JObj: TJSONObject;
  Path: string;
begin
  JObj := TJSONObject(ComboBoxPath.Items.Objects[aIdx]);
  Path := ConcatPaths([JObj.Strings['path'], 'fb3', '32']);

  AddDirDll(Path);
end;

function TFMedocCheckDocs.GetCurPathObj(): TJSONObject;
var
  Idx: integer;
begin
  if (ComboBoxPath.Items.Count > 0) then
  begin
    Idx := ComboBoxPath.ItemIndex;
    Result := TJSONObject(ComboBoxPath.Items.Objects[Idx]);
  end;
end;

procedure TFMedocCheckDocs.ConnectToDB();
var
  JObj: TJSONObject;
  DbName: string;
begin
  JObj := GetCurPathObj();
  DbName := JObj.Get('db', '');
  if (not DmCommon.IBConnection.Connected) or (DmCommon.IBConnection.DatabaseName <> DbName) then
  begin
    DmCommon.Connect(DbName, JObj.Get('port', 0));
    fTablesMain := DmCommon.GetTablesMain();
  end;
end;

procedure TFMedocCheckDocs.QueryOpen();
var
  Month, Year: integer;
  Str, StrDb, StrMacro: string;
begin
  SQLQueryGrid.Close();
  SQLQueryGrid.DataBase := DmCommon.IBConnection;
  SQLQueryGrid.Transaction := DmCommon.SQLTransaction;

  DbGrid.Columns.Clear();
  DbGrid.Visible := True;

  Month := integer(ComboBoxMonth.Items.Objects[ComboBoxMonth.ItemIndex]);
  Year := integer(ComboBoxYear.Items.Objects[ComboBoxYear.ItemIndex]);
  Str := FormatDateTime('yyyy-mm-dd', EncodeDate(Year, Month, 1));
  SQLQueryGrid.MacroByName('_PERDATE').Value := QuotedStr(Str);

  StrMacro := '';
  Str := UpperCase(ComboBoxDoc.Items.Names[ComboBoxDoc.ItemIndex]);
  if (not Str.IsEmpty()) then
    StrMacro := ' AND (UPPER(FORM.CHARCODE) = ' + QuotedStr(Str) + ')';
  SQLQueryGrid.MacroByName('_COND_CHARCODE').Value :=  StrMacro;

  StrMacro := '';
  Str := TRim(ComboBoxFirm.Text);
  if (not Str.IsEmpty()) then
    StrMacro := ' AND ORG.EDRPOU = ' + Str;
  SQLQueryGrid.MacroByName('_COND_ORG').Value := StrMacro;

  StrMacro := ', '''' AS FJ';
  if (Pos('J0500110', ComboBoxDoc.Text) = 1) then
  begin
    StrDb := 'FJ0500106_MAIN';
    if (fTablesMain.IndexOf(StrDb) <> 0) then
    begin
      StrMacro := ', TFJ.HZ || ''-'' || TFJ.HZN || ''-'' || TFJ.HZU AS FJ';
      SQLQueryGrid.MacroByName('_FROM_T2').Value := ' LEFT JOIN ' + StrDb + ' TFJ ON TFJ.CARDCODE = CARD.CODE';
    end;
  end;
  SQLQueryGrid.MacroByName('_SELECT_T2').Value := StrMacro;

  SQLQueryGrid.MacroByName('_ORDER').Value := fSortField;
  SQLQueryGrid.MacroByName('_ASC').Value := IfThen(fSortAsc, 'ASC', 'DESC');

  //SQLQueryGrid.AfterOpen := nil;
  //SQLQueryGrid.OnCalcFields := nil;
  //SQLQueryGrid.AfterScroll := nil;
  //DbGrid.OnDrawColumnCell := nil;

  //Str := ExpandSQL(SQLQueryGrid);
  //Log.Print(Str);

  //DmCommon.SQLTransaction.CommitRetaining();
  //DmCommon.SQLTransaction.Commit();
  DmCommon.SQLTransaction.Rollback();  //refresh
  SQLQueryGrid.Open();
  //SQLQueryGrid.Refresh();
end;

procedure TFMedocCheckDocs.SQLQueryGridCalcFields(DataSet: TDataSet);
var
  i, Month: integer;
  Field, FieldXML, FieldFJ, FieldHZ: TField;
  Code: string;
  Protected: boolean;
begin
  FieldXML := DataSet.FieldByName('XMLVALS');
  FieldFJ := DataSet.FieldByName('FJ');
  FieldHZ := DataSet.FieldByName('HZ');
  if (not FieldXML.IsNull) and (not FieldXML.AsString.IsEmpty()) then
    FieldHZ.AsString := GetHzXml(FieldXML.AsString)
  else if (not FieldFJ.AsString.IsEmpty()) then
    FieldHZ.AsString := GetHzStr(FieldFJ.AsString);

  Protected := ProtectTimer.CompareRnd();
  Code := DataSet.FieldByName('EDRPOU').AsString;
  if (fFirmCodesLicensed.IndexOf(Code) = -1) or (not Protected) then
    for i := 0 to fDemoFields.Count - 1 do
      DataSet.FieldByName(fDemoFields[i]).AsString := IfThen(Protected, 'ДЕМО', 'Д Е М О');

  Field := DataSet.FindField('PERDATE');
  if (Assigned(Field)) and (not Field.IsNull) then
  begin
    //DataSet.FindField('PERDATE_STR').AsString := FormatDateTime('mmmm', Field.AsDateTime);
    Month := MonthOf(Field.AsDateTime);
    DataSet.FindField('PERDATE_STR').AsString := GetMonthNameUa(Month);
  end;
end;

procedure TFMedocCheckDocs.ButtonExecClick(Sender: TObject);
var
  Msg, LastUpdate: string;
begin
  // we are not so fast comparing to MEDOC
  //Sleep(1000 + Random(500));

  LastUpdate := Settings.GetItem('Licence', 'LastUpdate', '');
  if (LastUpdate.IsEmpty()) then
    MenuItemRefreshClick(Nil)
  else if (DaysBetween(Now(), StrToDateTime(LastUpdate)) > cLicenceRefrehDays) then
    MenuItemRefreshClick(Nil);

  Msg := Format('%s %s, %s', [ComboBoxMonth.Text, ComboBoxYear.Text, ComboBoxDoc.Text]);
  Log.Print('i', Msg);

  ConnectToDb();
  QueryOpen();
end;

procedure TFMedocCheckDocs.ButtonActivationClick(Sender: TObject);
var
  P: TPoint;
begin
  P := ButtonActivation.ClientToScreen(Point(0, ButtonActivation.Height));
  PopupMenuActivation.PopUp(P.X, P.Y);
end;

procedure TFMedocCheckDocs.ComboBoxPathChange(Sender: TObject);
begin
  SetEmbededPath(ComboBoxPath.ItemIndex)
end;

procedure TFMedocCheckDocs.ComboBoxYearDropDown(Sender: TObject);
var
  Val: integer;
begin
  Val := StateStore.GetItem('FSettings', 'SpinEditBeginYear_Value', 0);
  SetComboBoxToYear(ComboBoxYear, Val);
end;

procedure TFMedocCheckDocs.DbGridDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: integer; Column: TColumn; State: TGridDrawState);
var
  //Code: string;
  DisplayText: string;
begin
  //Code := DbGrid.DataSource.DataSet.FieldByName('EDRPOU').AsString;

  // Встановлюємо колір фону та шрифт
  with DbGrid.Canvas do
  begin
    if gdSelected in State then
    begin
      Brush.Color := RGBToColor(254, 240, 220);
      Font.Color := clBlack;
    end else begin
      Brush.Color := DbGrid.Color;
      Font.Color := DbGrid.Font.Color;
    end;
    FillRect(Rect); // малюємо фон

    DisplayText := Column.Field.DisplayText;
    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, DisplayText);
  end;
end;

procedure TFMedocCheckDocs.DbGridTitleClick(Column: TColumn);
var
   fld: string;
begin
    fld := Column.FieldName;

    // якщо натиснули ту ж колонку — міняємо напрям
    if (fSortField = fld) then
      fSortAsc := (not fSortAsc)
    else begin
      fSortField := fld;
      fSortAsc := True;
    end;

    QueryOpen();
    DbGrid.Invalidate();
end;

procedure TFMedocCheckDocs.frReport1GetValue(const aParName: string; var aParValue: Variant);
begin
  if (aParName = 'AppName') then
    aParValue := cAppName;
end;

procedure TFMedocCheckDocs.MenuItemOrderClick(Sender: TObject);
begin
  ConnectToDb();
  DmCommon.Licence_OrderToHttp(Name);
end;

procedure TFMedocCheckDocs.MenuItemRefreshClick(Sender: TObject);
begin
  ConnectToDb();

  Log.Print('i', 'Завантаження ліцензій ...');
  fFirmCodesLicensed := DmCommon.Licence_GetFromHttp();
  Log.Print('i', 'Знайдено ліцензії для кодів ' + fFirmCodesLicensed.DelimitedText);
  Settings.SetItem('Licence', 'LastUpdate', DateTimeToStr(Now()));
end;

procedure TFMedocCheckDocs.ButtonPrintClick(Sender: TObject);
var
  PrevVisible: boolean;
begin
  if (SQLQueryGrid.RecordCount = 0) then
  begin
    Log.Print('i', 'Немає даних для друку');
    Exit;
  end;

  PrevVisible := SQLQueryGridINDTAXNUM.Visible;
  SQLQueryGridINDTAXNUM.Visible := False;
  FrPrintGrid1.Caption := Format(
   '%s -- Період: %s %s року--Звіт: %s)',
   [cAppName, ComboBoxMonth.Text, ComboBoxYear.Text, ComboBoxDoc.Text]
  );
  FrPrintGrid1.PreviewReport();
  SQLQueryGridINDTAXNUM.Visible := PrevVisible;

  //frReport1.LoadFromFile('Report\FMedocCheckDocs1.lrf');
  //if (frReport1.PrepareReport()) then
  //  frReport1.ShowReport();
end;

procedure TFMedocCheckDocs.ButtonRunMedocClick(Sender: TObject);
var
  JObj: TJSONObject;
begin
  JObj := GetCurPathObj();
  if (JObj.Get('port', 0) = 0) then
    Log.Print('i', 'Не мережева версія програми')
  else begin
    Log.Print('i', 'Запуск програми ' + ComboBoxPath.Text);
    ExecProcess(ComboBoxPath.Text);
  end;
end;

procedure TFMedocCheckDocs.FormCreate(Sender: TObject);
var
  i: integer;
  Str: string;
  JObj: TJSONObject;
begin
  fJMedocApp := Nil;
  fFirmCodesLicensed := Nil;
  fTablesMain := Nil;
  fDemoFields := Nil;

  fSortField := 'CARDSTATUS_NAME';
  fSortAsc := True;

  fJMedocApp := RegFindMedocInfo();
  for i := 0 to fJMedocApp.Count - 1 do
  begin
    JObj := fJMedocApp.Objects[i];
    Str := JObj.Get('path', '') + PathDelim + 'ezvit.exe';
    ComboBoxPath.Items.AddObject(Str, JObj);
  end;
  ButtonRunMedoc.Enabled := ComboBoxPath.Items.Count > 0;

  if (ComboBoxPath.Items.Count = 0) then
  begin
     Log.Print('w', 'Неможливо знайти програму звітності. Зверніться до свого дилера');
     ComboBoxPath.Text := '';
     Enabled := False;
  end else begin
     ComboBoxPath.ItemIndex := 0;
     SetEmbededPath(0);
  end;

  SetComboBoxToCurrentMonth(ComboBoxMonth);
  SetComboBoxDoc();
  ComboBoxYearDropDown(Nil);

  if (not Licence.IsFile()) then
     Log.Print('w', 'Файл ліцензій не знайдено');

  fFirmCodesLicensed := Licence.GetFirmCodes(Name);
  ComboBoxFirm.Items.Assign(fFirmCodesLicensed);
  ComboBoxFirm.Items.Insert(0, '');

  fDemoFields := TStringList.Create();
  fDemoFields.Add('CARDSTATUS_NAME');
  //fDemoFields.Add('MODDATE');
  fDemoFields.Add('CHARCODE');
  fDemoFields.Add('CARDSENDSTT_NAME');
  fDemoFields.Add('HZ');

  // Add cloumn visualisation in empty Grid
  for i := 0 to SQLQueryGrid.Fields.Count - 1 do
    if SQLQueryGrid.Fields[i].Visible then
      with DbGrid.Columns.Add do
        FieldName := SQLQueryGrid.Fields[i].DisplayLabel;

  Panel1.Font.Size := 10;
  StateStore.Load(self);

  fColorYelow := RGBToColor(255, 255, 153);
  StateStore.SetCtrlColor(self, fColorYelow, 'edit');
  //StateStore.SetCtrlColor(self, clWhite, 'button');
end;

procedure TFMedocCheckDocs.FormDestroy(Sender: TObject);
begin
  StateStore.Save(self);

  FreeAndNil(fJMedocApp);
  FreeAndNil(fFirmCodesLicensed);
  FreeAndNil(fTablesMain);
  FreeAndNil(fDemoFields);
end;

end.

