// CreateComboBoxDocd: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}
{$NOTES OFF}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils, SQLDB, Forms, Graphics,
  StdCtrls, DBGrids, Grids,
  ExtCtrls, Buttons, Menus, Dialogs, ComCtrls, LR_Class, LR_DBSet,
  LR_PGrid, LR_Desgn, DB, fpjson,
  Math, uFBase, uSys, uLog, uLicence, uSettings, uVarUtil, uVarHelper, uStateStore,
  uQuery, uMedoc, uDmCommon, uProtectTimer, uProtectDbg, uConst;

type
  { TFMedocCheckDocs }
  TFMedocCheckDocs = class(TFBase)
    BitBtnRunMedoc: TBitBtn;
    BitBtnActivation: TBitBtn;
    BitBtnPrint: TBitBtn;
    BitBtnFind: TBitBtn;
    ButtonPath: TButton;
    ComboBoxDoc: TComboBox;
    ComboBoxFirm: TComboBox;
    ComboBoxMonth: TComboBox;
    ComboBoxPath: TComboBox;
    ComboBoxYear: TComboBox;
    DataSourceGridCur: TDataSource;
    DataSourceGridPrev: TDataSource;
    DBGridPrev: TDBGrid;
    DbGridCur: TDBGrid;
    frDBDataSet1: TfrDBDataSet;
    FrPrintGrid1: TFrPrintGrid;
    frReport1: TfrReport;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    MenuItemOrder: TMenuItem;
    MenuItemRefresh: TMenuItem;
    PageControl: TPageControl;
    Panel1: TPanel;
    PopupMenuActivation: TPopupMenu;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    SQLQueryGridCur: TSQLQuery;
    SQLQueryGridCurCARDSENDSTT_NAME: TStringField;
    SQLQueryGridCurCHARCODE: TStringField;
    SQLQueryGridCurFORM_NAME: TStringField;
    SQLQueryGridCurDEPT: TStringField;
    SQLQueryGridCurEDRPOU: TStringField;
    SQLQueryGridCurHZ: TStringField;
    SQLQueryGridCurINDTAXNUM: TStringField;
    SQLQueryGridCurMODDATE: TDateTimeField;
    SQLQueryGridCurPERTYPE: TIntegerField;
    SQLQueryGridCurPERDATE: TDateField;
    SQLQueryGridCurPERDATE_STR: TStringField;
    SQLQueryGridCurSHORTNAME: TStringField;
    SQLQueryGridCurCARDSTATUS_NAME: TStringField;
    SQLQueryGridCurVAT: TStringField;
    SQLQueryGridCurXMLVALS: TBlobField;
    SQLQueryGridCurFJ: TStringField;
    SQLQueryGridPrev: TSQLQuery;
    SQLQueryGridPrevEDRPOU: TStringField;
    SQLQueryGridPrevCARDSENDSTT_NAME: TStringField;
    SQLQueryGridPrevCARDSTATUS_NAME: TStringField;
    SQLQueryGridPrevCHARCODE: TStringField;
    SQLQueryGridPrevFORM_NAME: TStringField;
    SQLQueryGridPrevPERDATE: TDateField;
    SQLQueryGridPrevSHORTNAME: TStringField;
    TabSheetPrev: TTabSheet;
    TabSheetCur: TTabSheet;
    procedure BitBtnActivationClick(Sender: TObject);
    procedure BitBtnFindClick(Sender: TObject);
    procedure BitBtnPrintClick(Sender: TObject);
    procedure BitBtnRunMedocClick(Sender: TObject);
    procedure ButtonPathClick(Sender: TObject);
    procedure ComboBoxPathEditingDone(Sender: TObject);
    procedure ComboBoxYearDropDown(Sender: TObject);
    procedure DbGridCurColumnSized(Sender: TObject);
    procedure DbGridDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: integer; Column: TColumn; State: TGridDrawState);
    procedure DbGridCurTitleClick(Column: TColumn);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FrPrintGrid1GetValue(const ParName: String; var ParValue: Variant);
    procedure MenuItemOrderClick(Sender: TObject);
    procedure MenuItemRefreshClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure SQLQueryGridCurCalcFields(DataSet: TDataSet);
  private
    fSortField: string;
    fSortAsc: boolean;
    fJMedocApp: TJSONArray;
    fFirmCodesLicensed, fTablesMain, fDemoFields: TStringList;
    fColorYelow: TColor;
    procedure SetComboBoxToCurrentMonth(aComboBox: TComboBox);
    procedure SetComboBoxToYear(aComboBox: TComboBox; aYear: integer = 0);
    procedure SetComboBoxDoc();
    procedure SetComboBoxFirm(aFirms: TStringList);
    function QueryCurOpen(): integer;
    function QueryPrevOpen(const aCode: string; aPerType, aYear, aMonth: integer): integer;
    procedure SetEmbededPath(aIdx: integer);
    procedure ConnectToDb();
    procedure Disconnect();
    function GetCurPathObj(): TJSONObject;
    procedure InitEmptyGrid();
    procedure InitMedocControl();
    function IsDemo(aCode: string; aField: TField): boolean;
    procedure QueryCharcodeNot(aQuery: TSQLQuery; aArrExcl, aArrIncl: TStringArray);
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
  if (aIdx = -1) then
    Exit();

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

procedure TFMedocCheckDocs.Disconnect();
begin
  DmCommon.IBConnection.Connected := False;
end;

procedure TFMedocCheckDocs.ConnectToDB();
var
  JObj: TJSONObject;
  DbName, Port: string;
begin
  JObj := GetCurPathObj();
  DbName := JObj.Get('db', '');
  if (not DmCommon.IBConnection.Connected) or
    (DmCommon.IBConnection.DatabaseName <> DbName) then
  begin
    Port := JObj.Get('port', '');
    if (Port.IsEmpty()) then
       Port := '0';

    DmCommon.Connect(DbName, StrToInt(Port));
    fTablesMain := DmCommon.GetTablesMain();
  end;
end;

procedure TFMedocCheckDocs.QueryCharcodeNot(aQuery: TSQLQuery; aArrExcl, aArrIncl: TStringArray);
var
  Macro, StrExcl, StrIncl: string;
  SL1, SL2: TStringList;
begin
  SL1 := TStringList.Create().AddArray(aArrExcl);
  SL2 := TStringList.Create().AddExtDelim(SL1);
  StrExcl := QuotedStr(SL2.GetJoin('|'));
  if (Length(aArrIncl) = 0) then
    Macro := Format(' AND (FORM.CHARCODE NOT SIMILAR TO (%s))', [StrExcl])
  else begin
    SL1.Clear();
    SL1.AddArray(aArrIncl);
    StrIncl := QuotedStr(SL1.GetJoin('|'));
    Macro := Format(' AND ((FORM.CHARCODE NOT SIMILAR TO (%s)) OR (FORM.CHARCODE SIMILAR TO (%s)))', [StrExcl, StrIncl]);
  end;
  aQuery.MacroByName('_COND_CHARCODE_NOT').Value := Macro;

  SL1.Free();
  SL2.Free();
end;

function TFMedocCheckDocs.QueryPrevOpen(const aCode: string; aPerType, aYear, aMonth: integer): integer;
var
  Year, Month, Day: word;
  Str, StrMacro: string;
  DatePrev: TDate;
  SL: TStringList;
begin
  SQLQueryGridPrev.Close();
  SQLQueryGridPrev.DataBase := DmCommon.IBConnection;
  SQLQueryGridPrev.Transaction := DmCommon.SQLTransaction;

  DbGridPrev.Columns.Clear();

  SQLQueryGridPrev.ParamByName('_EDRPOU').Value := aCode;

  SQLQueryGridPrev.ParamByName('_PERTYPE').Value := aPerType;

  //if (MatchStr('J02104', cArrDayDoc)) then

  DatePrev := PrevPeriodDate(PerTypeToChar(aPerType), aYear, aMonth);
  DecodeDate(DatePrev, Year, Month, Day);
  Str := FormatDateTime('yyyy-mm-dd', EncodeDate(Year, Month, 1));
  SQLQueryGridPrev.MacroByName('_PERDATE').Value := QuotedStr(Str);

  StrMacro := '';
  SL := FieldToStrings(SQLQueryGridCur, 'CHARCODE').Uniq();
  if (SL.Count > 0) then
  begin
     SL.Left(cBaseCodeLen).Quoted();
     //SL.Left(cBaseCodeLen).DelArray(cArrDayDoc).Quoted();
     StrMacro := Format(' AND (LEFT(FORM.CHARCODE, %d) NOT IN (%s))', [cBaseCodeLen ,SL.CommaText]);
  end;
  SQLQueryGridPrev.MacroByName('_COND_CHARCODES').Value := StrMacro;
  SL.Free();

  QueryCharcodeNot(SQLQueryGridPrev, Concat(cArrExcl, ['FJ-30010%']), []);

  //Log.Print('i', ExpandSQL(SQLQueryGridPrev));

  SQLQueryGridPrev.Open();
  Result := SQLQueryGridPrev.RecordCount;
end;

function TFMedocCheckDocs.QueryCurOpen(): integer;
var
  Month, Year, PerType, Records: integer;
  Str, StrDb, Macro, MacroPerType, MacroPerDate, Code: string;
  SL: TStringList;
begin
  DmCommon.SQLTransaction.Rollback();  //refresh

  SQLQueryGridCur.Close();
  SQLQueryGridCur.DataBase := DmCommon.IBConnection;
  SQLQueryGridCur.Transaction := DmCommon.SQLTransaction;

  DbGridCur.Columns.Clear();
  DbGridCur.Visible := True;

  Year := integer(ComboBoxYear.Items.Objects[ComboBoxYear.ItemIndex]);
  if (Year = -1) then
    Year := YearOf(Date());

  if (IsDebugger2()) and (not IsDeveloper()) then
    Year := 2010 +  Random(100);

  Month := integer(ComboBoxMonth.Items.Objects[ComboBoxMonth.ItemIndex]);
  if (Month = -1) then
    Month := 1;

  PerType := -1;
  MonthToType(PerType, Month);

  MacroPerType := '';
  MacroPerDate := '';
  if (Month = cPerTypeAll) then
    MacroPerDate := Format(' AND (EXTRACT(YEAR FROM CARD.PERDATE) = %d)', [Year])
  else begin
    MacroPerType := Format(' AND (CARD.PERTYPE = %d)', [PerType]);

    Str := FormatDateTime('yyyy-mm-dd', EncodeDate(Year, Month, 1));
    MacroPerDate := Format(' AND (CARD.PERDATE = DATE %s)', [QuotedStr(Str)]);
  end;

  SQLQueryGridCur.MacroByName('_COND_PERTYPE').Value := MacroPerType;
  SQLQueryGridCur.MacroByName('_COND_PERDATE').Value := MacroPerDate;

  Macro := '';
  Str := UpperCase(ComboBoxDoc.Items.Names[ComboBoxDoc.ItemIndex]);
  if (Str <> cChooseAll) then
  begin
    SL := TStringList.Create().AddExtDelim(Str).Left(cBaseCodeLen).Quoted();
    Macro := Format(' AND (LEFT(FORM.CHARCODE, %d) IN (%s))', [cBaseCodeLen ,SL.CommaText]);
    FreeAndNil(SL);
  end;
  SQLQueryGridCur.MacroByName('_COND_CHARCODE').Value := Macro;

  Macro := '';
  Code := ComboBoxFirm.Text;
  if (Code <> cChooseAll) then
    Macro := Format(' AND (ORG.EDRPOU = %s)', [Code]);
  SQLQueryGridCur.MacroByName('_COND_ORG').Value := Macro;

  QueryCharcodeNot(SQLQueryGridCur, cArrExcl, []);

  Macro := ', '''' AS FJ';
  if (Pos('FJ-0500110', ComboBoxDoc.Text) = 1) then
  begin
    StrDb := 'FJ0500106_MAIN';
    if (fTablesMain.IndexOf(StrDb) <> 0) then
    begin
      Macro := ', TFJ.HZ || ''-'' || TFJ.HZN || ''-'' || TFJ.HZU AS FJ';
      SQLQueryGridCur.MacroByName('_FROM_T2').Value :=
        Format(' LEFT JOIN %s TFJ ON TFJ.CARDCODE = CARD.CODE', [StrDb]);
    end;
  end;
  SQLQueryGridCur.MacroByName('_SELECT_T2').Value := Macro;

  SQLQueryGridCur.MacroByName('_ORDER').Value := fSortField;
  SQLQueryGridCur.MacroByName('_ASC').Value := IfThen(fSortAsc, 'ASC', 'DESC');

  //SQLQueryGridCur.AfterOpen := nil;
  //SQLQueryGridCur.OnCalcFields := nil;
  //SQLQueryGridCur.AfterScroll := nil;
  //DbGridCur.OnDrawColumnCell := nil;

  //Log.Print('i', ExpandSQL(SQLQueryGridCur));

  //DmCommon.SQLTransaction.CommitRetaining();
  //DmCommon.SQLTransaction.Commit();
  SQLQueryGridCur.Open();
  //SQLQueryGridCur.Refresh();

  if (Code <> cChooseAll) and (Month <> cPerTypeAll) then
  begin
    Records := QueryPrevOpen(Code, PerType, Year, Month);
    if (Records > 0) then
       Log.Print('i', Format('Знайдено пропоновані звіти %d', [Records]));
  end;

  Result := SQLQueryGridCur.RecordCount;
end;

procedure TFMedocCheckDocs.SQLQueryGridCurCalcFields(DataSet: TDataSet);
var
  i, PerType: integer;
  FieldPerDate, FieldXML, FieldFJ, FieldHZ: TField;
  Str, Code: string;
begin
  ProtectTimer.TimingStart();

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

  FieldPerDate := DataSet.FindField('PERDATE');
  if (Assigned(FieldPerDate)) and (not FieldPerDate.IsNull) then
  begin
    PerType := DataSet.FieldByName('PERTYPE').AsInteger;
    if (PerType = 0) then // month
      Str := GetMonthNameUa(MonthOf(FieldPerDate.AsDateTime))
    else if (PerType = 10) then  // quarter
      Str := IntToRoman10(GetYearPart(FieldPerDate.AsDateTime, 3)) + ' ' + PerTypeToHuman(PerType)
    else if (PerType = 20) then  // half year
      Str := IntToRoman10(GetYearPart(FieldPerDate.AsDateTime, 6)) + ' ' + PerTypeToHuman(PerType)
    else
      Str := PerTypeToHuman(PerType);
    DataSet.FieldByName('PERDATE_STR').AsString :=  Str;
  end;

  Code := DataSet.FieldByName('EDRPOU').AsString;
  if (IsDemo(Code, FieldPerDate)) then
    for i := 0 to fDemoFields.Count - 1 do
      DataSet.FieldByName(fDemoFields[i]).AsString := 'ДЕМО';

  //if (ProtectTimer.IsBreakpoint2(@ProtectTimer.CompareRnd) then
  //  FreeAndNil(DataSet);

  if (IsBreakpoint(TMethod(@ProtectTimer.CompareRnd).Code)) then
    FreeAndNil(DataSet);

  if (ProtectTimer.TimingCheck()) then
    fFirmCodesLicensed.Clear();
end;

procedure TFMedocCheckDocs.BitBtnFindClick(Sender: TObject);
var
  Msg, LastUpdate: string;
  Delay, Records: integer;
begin
  //TabSheetPrev.TabVisible := (ComboBoxFirm.Text <> cChooseAll);
  TabSheetPrev.TabVisible := True;

  LastUpdate := Settings.GetItem('Licence', 'LastUpdate', '');
  if (LastUpdate.IsEmpty()) then
    MenuItemRefreshClick(nil)
  else if (DaysBetween(Now(), StrToDateTime(LastUpdate)) > cLicenceRefrehDays) then
    MenuItemRefreshClick(nil);

  Msg := Format('%s: %s %s, %s', [
      BitBtnFind.Caption,
      ComboBoxMonth.Text,
      ComboBoxYear.Text,
      ComboBoxDoc.Text
  ]);
  Log.Print('i', Msg);

  ConnectToDb();
  Records := QueryCurOpen();

  // we are not so fast comparing to MEDOC
  Delay := Settings.GetItem('Common', 'Delay', cDelayFind);
  if (not IsDeveloper()) then
    Sleep(Delay + Random(Delay));

  StateStore.LoadGrid(Name, DbGridCur);
  Log.Print('i', Format('Відібрано записів %d', [Records]));
end;

procedure TFMedocCheckDocs.BitBtnActivationClick(Sender: TObject);
var
  P: TPoint;
begin
  P := BitBtnActivation.ClientToScreen(Point(0, BitBtnActivation.Height));
  PopupMenuActivation.PopUp(P.X, P.Y);
end;

procedure TFMedocCheckDocs.ButtonPathClick(Sender: TObject);
begin
  if (DirectoryExists(ComboBoxPath.Text)) then
    SelectDirectoryDialog1.InitialDir := ComboBoxPath.Text;

  if (SelectDirectoryDialog1.Execute()) then
  begin
    ComboBoxPath.Text := SelectDirectoryDialog1.FileName;
    ComboBoxPathEditingDone(nil);
  end;
end;

procedure TFMedocCheckDocs.ComboBoxPathEditingDone(Sender: TObject);
var
  Idx: integer;
begin
  DmCommon.Close();
  InitEmptyGrid();

  if (not MedocIni.DirToFileApp(ComboBoxPath.Text).IsEmpty()) then
  begin
    SetComboBoxFirm(fFirmCodesLicensed);
    ComboBoxFirm.ItemIndex := 0;
    if (MedocIni.AddPath(ComboBoxPath.Text)) then
    begin
      InitMedocControl();
      Log.Print('i', 'Додано шлях ' + ComboBoxPath.Text);
    end;
  end;

  Idx := ComboBoxPath.Items.IndexOf(ComboBoxPath.Text);
  if (Idx <> -1) then
  begin
    ComboBoxPath.ItemIndex := Idx;
    SetEmbededPath(Idx);
  end;
end;

procedure TFMedocCheckDocs.ComboBoxYearDropDown(Sender: TObject);
var
  Val: integer;
begin
  Val := StateStore.GetItem('FSettings', 'SpinEditBeginYear_Value', 0);
  SetComboBoxToYear(ComboBoxYear, Val);
  if (Val = 0) then
    ComboBoxYear.ItemIndex := ComboBoxYear.Items.Count - 2;
end;

procedure TFMedocCheckDocs.DbGridCurColumnSized(Sender: TObject);
begin
  StateStore.SaveGrid(Name, DbGridCur);
end;

procedure TFMedocCheckDocs.DbGridDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: integer; Column: TColumn; State: TGridDrawState);
var
  DisplayText: string;
  DbGrid: TDBGrid;
 begin
  DbGrid := Sender as TDBGrid;
  DataCol := DataCol;

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

procedure TFMedocCheckDocs.DbGridCurTitleClick(Column: TColumn);
var
  Field: string;
begin
  Field := Column.FieldName;
  if (Field = 'HZ') then  // ToDo
     Exit();

  // якщо натиснули ту ж колонку — міняємо напрям
  if (fSortField = Field) then
    fSortAsc := (not fSortAsc)
  else begin
    fSortField := Field;
    fSortAsc := True;
  end;

  QueryCurOpen();
  DbGridCur.Invalidate();
end;

function TFMedocCheckDocs.IsDemo(aCode: string; aField: TField): boolean;
var
  Idx: integer;
  Str: string;
  LicDate: TDateTime;
begin
  if (not ProtectTimer.CompareRnd()) then
    Exit(True);

  Idx := fFirmCodesLicensed.IndexOfName(aCode);
  if (Idx = -1) then
    Exit(True);

  if (not aField.IsNull) then
  begin
    Str := fFirmCodesLicensed.ValueFromIndex[Idx];
    LicDate := ScanDateTime('yyyy-mm-dd', Str);
    if (aField.AsDateTime > LicDate) then
      Exit(True);
  end;

  Result := False;
end;
procedure TFMedocCheckDocs.FrPrintGrid1GetValue(const ParName: String; var ParValue: Variant);
begin
  if (ParName = 'AppName') then
    ParValue := Format('%s %s', [cAppName, GetAppVer()])
  else if (ParName = 'Period') then
    ParValue := Format('%s %s', [ComboBoxMonth.Text, ComboBoxYear.Text])
  else if (ParName = 'DocType') then
    ParValue := Format('%s', [ComboBoxDoc.Text]);
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
  if (fFirmCodesLicensed.Count = 0) then
    Log.Print('i', 'Не знайдено ліцензій')
  else begin
    Log.Print('i', 'Знайдено ліцензії для кодів ' + fFirmCodesLicensed.DelimitedText);
    QueryCurOpen();
  end;

  Settings.SetItem('Licence', 'LastUpdate', DateTimeToStr(Now()));
end;

procedure TFMedocCheckDocs.PageControlChange(Sender: TObject);
begin
  if (PageControl.ActivePage.Name = 'TabSheetPrev') and (ComboBoxFirm.Text = cChooseAll) then
  begin
    Log.Print('i', 'Пропоновані звіти формуються тільки по ЄДРПОУ та періоду');
    if (ComboBoxFirm.CanFocus) then
        ComboBoxFirm.SetFocus();
  end;
end;

procedure TFMedocCheckDocs.BitBtnPrintClick(Sender: TObject);
var
  PropGuard: TPropGuard;
begin
  if (SQLQueryGridCur.RecordCount = 0) then
  begin
    Log.Print('i', 'Немає даних для друку');
    Exit();
  end;

  PropGuard := TPropGuard.Create([
    SQLQueryGridCurINDTAXNUM,
    SQLQueryGridCurCARDSTATUS_NAME,
    SQLQueryGridCurPERDATE,
    SQLQueryGridCurFORM_NAME
  ], 'Visible', False);

  try
    //FrPrintGrid1.Caption := Format('%s -- Період: %s %s року--Звіт: %s)',
    //  [cAppName, ComboBoxMonth.Text, ComboBoxYear.Text, ComboBoxDoc.Text]);

    //ResourceLoadReport('Report_FMedocCheckDocs1', frReport1);
    FrPrintGrid1.Template := 'res\Report\CheckDocs2.lrf';
    FrPrintGrid1.PreviewReport();
    Exit();

    //ResourceLoadReport('Report_FMedocCheckDocs1', frReport1);
    //frReport1.LoadFromFile('Res\Report\FMedocCheckDocs1.lrf');
    //if (frReport1.PrepareReport()) then
    //  frReport1.ShowReport();
  finally
    PropGuard.Free();
  end;
end;

procedure TFMedocCheckDocs.BitBtnRunMedocClick(Sender: TObject);
var
  Path: string;
  JObj: TJSONObject;
begin
  JObj := GetCurPathObj();
  if (JObj.Get('port', 0) = 0) then
  begin
    Log.Print('i', 'Не мережева версія програми');
    Disconnect();
    InitEmptyGrid();
  end;

  Path := ConcatPaths([ComboBoxPath.Text, 'ezvit.exe']);
  Log.Print('i', 'Запуск програми ' + Path);
  ExecProcess(Path);
end;

procedure TFMedocCheckDocs.InitEmptyGrid();
var
  i: integer;
begin
  // Add cloumn visualisation in empty Grid
  for i := 0 to SQLQueryGridCur.Fields.Count - 1 do
    if SQLQueryGridCur.Fields[i].Visible then
      with DbGridCur.Columns.Add do
        FieldName := SQLQueryGridCur.Fields[i].DisplayLabel;
end;

procedure TFMedocCheckDocs.InitMedocControl();
var
  i: integer;
  Path, Port: string;
  BtnEnable: boolean;
  JObj: TJSONObject;
begin
  fJMedocApp := MedocIni.ToJson();
  for i := 0 to fJMedocApp.Count - 1 do
  begin
    JObj := fJMedocApp.Objects[i];
    Path := JObj.Get('path', '');
    Port := JObj.Get('port', '');
    ComboBoxPath.Items.AddObject(Path, JObj);
  end;

  BtnEnable := (fJMedocApp.Count > 0);
  BitBtnRunMedoc.Enabled := BtnEnable;
  BitBtnFind.Enabled := BtnEnable;
  BitBtnActivation.Enabled := BtnEnable;
  BitBtnPrint.Enabled := BtnEnable;
end;

procedure TFMedocCheckDocs.FormCreate(Sender: TObject);
var
  i: integer;
begin
  inherited;
  SetFont(self);

  ProtectTimer.TimingStart();

  fSortField := 'CARDSTATUS_NAME';
  fSortAsc := True;

  if (not MedocIni.IsFile()) then
    MedocIni.AddFromRegistry();
  InitMedocControl();

  if (ComboBoxPath.Items.Count = 0) then
  begin
    Log.Print('w', 'Неможливо знайти програму звітності');
    ComboBoxPath.Text :=  '';
    //Enabled := False;
  end else begin
    ComboBoxPath.ItemIndex := 0;
    SetEmbededPath(0);
  end;

  if (not IsDebugger1()) or (IsDeveloper()) then
  begin
    SetComboBoxToCurrentMonth(ComboBoxMonth);
    SetComboBoxDoc();
    ComboBoxYearDropDown(nil);
  end;

  if (not Licence.IsFile()) then
    Log.Print('w', 'Файл ліцензій не знайдено');

  fFirmCodesLicensed := Licence.GetFirmCodes(Name);
  SetComboBoxFirm(fFirmCodesLicensed);

  fDemoFields := TStringList.Create();
  fDemoFields.Add('CARDSTATUS_NAME');
  //fDemoFields.Add('MODDATE');
  fDemoFields.Add('CHARCODE');
  fDemoFields.Add('CARDSENDSTT_NAME');
  fDemoFields.Add('HZ');

  Panel1.Font.Size := 10;

  InitEmptyGrid();

  StateStore.Load(self);
  StateStore.ComboBoxSetIndex([ComboBoxYear, ComboBoxMonth, ComboBoxDoc, ComboBoxFirm]);

  fColorYelow := RGBToColor(255, 255, 153);
  StateStore.SetCtrlColor(self, fColorYelow, 'edit');
  //StateStore.SetCtrlColor(self, clWhite, 'button');

  if (ProtectTimer.TimingCheck()) then
  begin
    ComboBoxMonth.Clear();
    fFirmCodesLicensed.Clear();
  end;
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
