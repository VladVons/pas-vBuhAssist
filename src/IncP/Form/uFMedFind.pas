// CreateComboBoxDocd: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedFind;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Buttons, Graphics,
  DBGrids, Dialogs, Menus, LR_Class, LR_DBSet, LR_PGrid, SQLDB, DB, Grids, fpjson, jsonparser,
  DateUtils, Math, StrUtils,
  uDmCommon,
  uFBase, uConst, uMed, uSys, uSysVcl, uVarHelper, uVarUtil, uQuery, uProtectDbg, uProtectTimer,
  uLog, uSettings, uStateStore, uLicence;

type
  { TFMedFind }
  {$I uFMedFind.pas.inc}

implementation
{$R *.lfm}

procedure TFMedFind.Log(aType: char; const aMsg: string);
begin
  uLog.Log.Print(aType, Format('%s %s', [Caption, aMsg]));
end;

function TFMedFind.GetParentDocsExcl(): TStringList;
begin
  Result := Nil;
end;

procedure TFMedFind.ParentCalcFields(DataSet: TDataSet);
begin
end;

procedure TFMedFind.ParentQueryCurOpen(aQuery: TSQLQuery);
begin
end;

procedure TFMedFind.LoadJsonData();
var
  Str, Path: string;
  SL: TStringList;
  Arr: TJSONArray;
begin
  Path := ConcatPaths(['res', 'Json', Name + '.json']);
  if (FileExists(Path)) then
    fJData := TJSONObject(FileLoadJson(Path))
  else begin
    Path := 'Json_' + Name;
    Str := ResourceLoadString(Path);
    if (Str.IsEmpty()) then
      Log('e', 'Не знайдено ресурс ' + Path);
    fJData := TJSONObject(GetJSON(Str));
  end;

  Arr := (fJData.FindPath('Controls') as TJSONObject).Arrays['ComboBoxMonth'];
  SL := TStringList.Create().AddJson(Arr);
  SetComboBoxAsObj(ComboBoxMonth, SL);
  SL.Free();

  Arr := (fJData.FindPath('Controls') as TJSONObject).Arrays['ComboBoxDoc'];
  SL := TStringList.Create().AddJson(Arr);
  SetComboBoxAsPair(ComboBoxDoc, SL);
  SL.Free();

  Arr := (fJData.FindPath('Controls') as TJSONObject).Arrays['ComboBoxSendStatus'];
  SL := TStringList.Create().AddJson(Arr);
  SetComboBoxAsObj(ComboBoxSendStatus, SL);
  SL.Free();
end;

procedure TFMedFind.SetComboBox(aComboBox: TComboBox; aSL: TStringList);
var
  i: integer;
begin
  aComboBox.Clear();
  aComboBox.Items.Add(cChooseAll);
  for i := 0 to aSL.Count - 1 do
    aComboBox.Items.Add(aSL.Names[i]);

  aComboBox.ItemIndex := 0;
end;

procedure TFMedFind.SetComboBoxAsPair(aComboBox: TComboBox; aSL: TStringList);
var
  i: integer;
begin
  ComboBoxDoc.Clear();
  ComboBoxDoc.Items.AddPair(cChooseAll, '');
  for i := 0 to aSL.Count - 1 do
    ComboBoxDoc.Items.Add(aSL[i]);

  ComboBoxDoc.ItemIndex := 0;
end;

procedure TFMedFind.SetComboBoxAsObj(aComboBox: TComboBox; aSL: TStringList);
var
  i, Idx: integer;
begin
  with aComboBox.Items do
  begin
    Clear();
    AddObject(cChooseAll, TObject(cPerTypeAll));
    for i := 0 to aSL.Count - 1 do
    begin
      Idx := aSL.Names[i].ToInteger();
      AddObject(aSL.ValueFromIndex[i], TObject(Idx));
    end;
  end;

  aComboBox.ItemIndex := 0;
end;

procedure TFMedFind.SetComboBoxYear(aYear: Integer = 0);
var
  i, YearNext: Integer;
begin
  YearNext := YearOf(IncYear(Date(), 1));
  if (aYear = 0) then
    aYear := YearOf(IncYear(Date(), -cYearsBack));
  aYear := Max(aYear, YearNext - 15);

  ComboBoxYear.Items.Clear();
  for i := aYear to YearNext do
    ComboBoxYear.Items.AddObject(IntToStr(i), TObject(i));
end;

function TFMedFind.GetCurPathObj(): TJSONObject;
var
  Idx: integer;
begin
  if (ComboBoxPath.Items.Count > 0) then
  begin
    Idx := ComboBoxPath.ItemIndex;
    Result := TJSONObject(ComboBoxPath.Items.Objects[Idx]);
  end;
end;

procedure TFMedFind.SetEmbededPath(aIdx: integer);
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

procedure TFMedFind.Disconnect();
begin
  DmCommon.IBConnection.Connected := False;
end;

procedure TFMedFind.ConnectToDB();
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

    DmCommon.Connect(DbName, Port.ToInteger());
    fTablesMain := DmCommon.GetTablesMain();
  end;
end;

function TFMedFind.QueryPrevOpen(aQuery: TSQLQuery; aSLCodes: TStringList; const aCode: string; aPerType, aYear, aMonth: integer): integer;
var
  Year, Month, Day: word;
  Str, StrMacro: string;
  DatePrev: TDate;
begin
  aQuery.Close();

  DbGridPrev.Columns.Clear();

  aQuery.ParamByName('_EDRPOU').Value := aCode;

  aQuery.ParamByName('_PERTYPE').Value := aPerType;

  DatePrev := PrevPeriodDate(PerTypeToChar(aPerType), aYear, aMonth);
  DecodeDate(DatePrev, Year, Month, Day);
  Str := FormatDateTime('yyyy-mm-dd', EncodeDate(Year, Month, 1));
  aQuery.MacroByName('_PERDATE').Value := QuotedStr(Str);

  StrMacro := '';
  if (aSLCodes.Count > 0) then
  begin
     aSLCodes.Left(cBaseCodeLen).Quoted();
     //SL.Left(cBaseCodeLen).DelArray(cArrDayDoc).Quoted();
     StrMacro := Format(' AND (LEFT(FORM.CHARCODE, %d) NOT IN (%s))', [cBaseCodeLen ,aSLCodes.CommaText]);
  end;
  aQuery.MacroByName('_COND_CHARCODES').Value := StrMacro;

  //QueryCharcodeNot(aQuery, Concat(GetParentDocsExcl(), ['FJ-30010%']));

  //Log.Print('i', ExpandSQL(SQLQueryGridPrev));

  aQuery.Open();
  Result := aQuery.RecordCount;
end;

function TFMedFind.QueryCurOpen(aQuery, aQueryPrev: TSQLQuery): integer;
var
  Int, Month, Year, PerType, Records: integer;
  Str, StrDb, Macro, MacroPerType, MacroPerDate, Code: string;
  SL: TStringList;
begin
  GetParentTransaction().Rollback();  //refresh
  aQuery.Close();

  DbGridCur.Columns.Clear();
  DbGridCur.Visible := True;

  Year := integer(ComboBoxYear.Items.Objects[ComboBoxYear.ItemIndex]);
  if (Year = -1) then
    Year := YearOf(Date());

  Month := integer(ComboBoxMonth.Items.Objects[ComboBoxMonth.ItemIndex]);
  if (Month = -1) then
    Month := 1;

  if (IsDebugger2()) and (not IsDeveloper()) then
  begin
    Year := 2010 +  Random(100);
    month := 1 + Random(11);
  end;

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
  aQuery.MacroByName('_COND_PERTYPE').Value := MacroPerType;
  aQuery.MacroByName('_COND_PERDATE').Value := MacroPerDate;

  Macro := '';
  Code := ComboBoxFirm.Text;
  if (Code <> cChooseAll) then
    Macro := Format(' AND (ORG.EDRPOU = %s)', [Code]);
  aQuery.MacroByName('_COND_ORG').Value := Macro;

  Macro := '';
  Int := integer(ComboBoxSendStatus.Items.Objects[ComboBoxSendStatus.ItemIndex]);
  if (Int <> cPerTypeAll) then
    Macro := Format(' AND (CARD.SENDSTT = %d)', [Int]);
  aQuery.MacroByName('_COND_SENDSTT').Value := Macro;

  Str := ComboBoxDoc.Items.Names[ComboBoxDoc.ItemIndex];
  if (Str = cChooseAll) then
    SL := GetParentDocsIncl()
  else
    SL := TStringList.Create().AddExtDelim(Str).Left(cBaseCodeLen);

  if (SL.Count > 0) then
    Macro := Format(' AND (LEFT(FORM.CHARCODE, %d) IN (%s))', [cBaseCodeLen ,SL.Quoted().CommaText])
  else
    Macro := '';
  aQuery.MacroByName('_COND_CHARCODE').Value := Macro;
  FreeAndNil(SL);

  ParentQueryCurOpen(aQuery);

  aQuery.MacroByName('_ORDER').Value := fSortField;
  aQuery.MacroByName('_ASC').Value := IfThen(fSortAsc, 'ASC', 'DESC');

  Log('i', ExpandSQL(aQuery));
  aQuery.Open();

  if (Code <> cChooseAll) and (Month <> cPerTypeAll) then
  begin
    SL := FieldToStrings(aQuery, 'CHARCODE').Uniq();
    Records := QueryPrevOpen(aQueryPrev, SL, Code, PerType, Year, Month);
    if (Records > 0) then
       Log('i', Format('Знайдено пропоновані звіти %d', [Records]));
    SL.Free();

    Str := IntToStr(Records);
    DBGridPrev.Visible := True;
  end else begin
    Str := '?';
    DBGridPrev.Visible := False;
  end;

  TabSheetCur.Caption := Format('%s (%d)', [fCurCaption, aQuery.RecordCount]) ;
  TabSheetPrev.Caption := Format('%s (%s)', [fPrevCaption, Str]) ;

  Result := aQuery.RecordCount;
end;

procedure TFMedFind.SQLQueryGridCurCalcFields(DataSet: TDataSet);
var
  i, PerType: integer;
  FieldPerDate: TField;
  Str, Code: string;
begin
  ProtectTimer.TimingStart();

  FieldPerDate := DataSet.FindField('PERDATE');
  if (Assigned(FieldPerDate)) and (not FieldPerDate.IsNull) then
  begin
    PerType := DataSet.FieldByName('PERTYPE').AsInteger;
    if (PerType = cDbMonth) then
      Str := GetMonthNameUa(MonthOf(FieldPerDate.AsDateTime))
    else if (PerType = cDbQuarter) then
      Str := IntToRoman10(GetYearPart(FieldPerDate.AsDateTime, 3)) + ' ' + PerTypeToHuman(PerType)
    else if (PerType = cDbYearHalf) then
      Str := IntToRoman10(GetYearPart(FieldPerDate.AsDateTime, 6)) + ' ' + PerTypeToHuman(PerType)
    else
      Str := PerTypeToHuman(PerType);
    DataSet.FieldByName('PERDATE_STR').AsString :=  Str;
  end;

  ParentCalcFields(DataSet);

  if (fCount > 5) then
  begin
    Code := DataSet.FieldByName('EDRPOU').AsString;
    if (IsDemo(Code, FieldPerDate)) then
      for i := 0 to fDemoFields.Count - 1 do
        DataSet.FieldByName(fDemoFields[i]).AsString := 'ДЕМО';
  end;

  if (IsBreakpoint(TMethod(@ProtectTimer.CompareRnd).Code)) then
    FreeAndNil(DataSet);

  if (ProtectTimer.TimingCheck()) then
    fCodesLic.Clear();
end;

procedure TFMedFind.BitBtnFindClick(Sender: TObject);
var
  Msg, LastUpdate: string;

  Delay, Records: integer;
begin
  Inc(fCount);

  //TabSheetPrev.TabVisible := (ComboBoxFirm.Text <> cChooseAll);
  TabSheetPrev.TabVisible := True;

  LastUpdate := Settings.GetItem('Licence', 'LastUpdate', '');
  if (LastUpdate.IsEmpty()) then
    MenuItemRefreshClick(nil)
  else if (DaysBetween(Now(), StrToDateTime(LastUpdate)) > cLicenceRefrehDays) then
    MenuItemRefreshClick(nil);

  Msg := Format('%s %s %s %s', [
    BitBtnFind.Caption,  ComboBoxMonth.Text,  ComboBoxYear.Text, ComboBoxDoc.Text
  ]);
  Log('i', Msg);

  ConnectToDb();
  Records := QueryCurOpen(GetParentQueryCur(), GetParentQueryPrev());

  // we are not so fast comparing to MED
  Delay := Settings.GetItem('Common', 'Delay', cDelayFind);
  if (not IsDeveloper()) then
    Sleep(Delay + Random(Delay));

  StateStore.LoadGrid(Name, DbGridCur);
  Log('i', Format('Відібрано записів %d', [Records]));
end;

procedure TFMedFind.BitBtnActivationClick(Sender: TObject);
var
  P: TPoint;
begin
  P := BitBtnActivation.ClientToScreen(Point(0, BitBtnActivation.Height));
  PopupMenuActivation.PopUp(P.X, P.Y);
end;

procedure TFMedFind.ButtonPathClick(Sender: TObject);
begin
  if (DirectoryExists(ComboBoxPath.Text)) then
    SelectDirectoryDialog1.InitialDir := ComboBoxPath.Text;

  if (SelectDirectoryDialog1.Execute()) then
  begin
    ComboBoxPath.Text := SelectDirectoryDialog1.FileName;
    ComboBoxPathEditingDone(nil);
  end;
end;

function TFMedFind.OnSendMsg(aForm: TForm; const aJObj: TJSONObject): boolean;
var
  id: string;
begin
  if (Assigned(aJObj)) then
  begin
   id := aJObj.Get('id', '');
   if (id = 'combobox_path_db') then
   begin
     ComboBoxPath.ItemIndex := aJObj.Get('index', 0);
     ComboBoxPathEditingDone(Nil);
   end;
  end;

  Result := False;
end;

procedure TFMedFind.ComboBoxPathEditingDone(Sender: TObject);
var
  Idx: integer;
  JObj: TJSONObject;
begin
  // prevent recursion from OnSendMsgs
  if (not Assigned(Sender)) then
    Exit;

  DmCommon.Close();
  InitEmptyGrid(GetParentQueryCur());

  if (not MedIni.DirToFileApp(ComboBoxPath.Text).IsEmpty()) then
  begin
    SetComboBox(ComboBoxFirm, fCodesLic);
    ComboBoxFirm.ItemIndex := 0;
    if (MedIni.AddPath(ComboBoxPath.Text)) then
    begin
      InitMedControl();
      Log('i', 'Додано шлях ' + ComboBoxPath.Text);
    end;
  end;

  Idx := ComboBoxPath.Items.IndexOf(ComboBoxPath.Text);
  if (Idx <> -1) then
  begin
    ComboBoxPath.ItemIndex := Idx;
    SetEmbededPath(Idx);

    JObj := TJSONObject.Create();
    JObj.Add('id', 'combobox_path_db');
    JObj.Add('index', Idx);
    SendMsg(JObj);
    JObj.Free();
  end;
end;

procedure TFMedFind.ComboBoxYearDropDown(Sender: TObject);
var
  Val: integer;
begin
  Val := StateStore.GetItem('FSettings', 'SpinEditBeginYear_Value', 0);
  SetComboBoxYear(Val);
  if (Val = 0) then
    ComboBoxYear.ItemIndex := ComboBoxYear.Items.Count - 2;
end;

procedure TFMedFind.DbGridCurColumnSized(Sender: TObject);
begin
  StateStore.SaveGrid(Name, DbGridCur);
end;

procedure TFMedFind.DbGridDrawColumnCell(Sender: TObject;
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

procedure TFMedFind.DbGridCurTitleClick(Column: TColumn);
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

  QueryCurOpen(GetParentQueryCur(), GetParentQueryPrev());
  DbGridCur.Invalidate();
end;

function TFMedFind.IsDemo(aCode: string; aField: TField): boolean;
var
  Idx: integer;
  Str: string;
  LicDate: TDateTime;
begin
  if (not ProtectTimer.CompareRnd()) then
    Exit(True);

  Idx := fCodesLic.IndexOfName(aCode);
  if (Idx = -1) then
    Exit(True);

  if (not aField.IsNull) then
  begin
    Str := fCodesLic.ValueFromIndex[Idx];
    LicDate := ScanDateTime('yyyy-mm-dd', Str);
    if (aField.AsDateTime > LicDate) then
      Exit(True);
  end;

  Result := False;
end;

procedure TFMedFind.FrPrintGrid1GetValue(const ParName: String; var ParValue: Variant);
begin
  if (ParName = 'AppName') then
    ParValue := Format('%s %s', [cAppName, GetAppVer()])
  else if (ParName = 'Period') then
    ParValue := Format('%s %s', [ComboBoxMonth.Text, ComboBoxYear.Text])
  else if (ParName = 'DocType') then
    ParValue := Format('%s', [ComboBoxDoc.Text]);
end;

procedure TFMedFind.MenuItemOrderClick(Sender: TObject);
begin
  ConnectToDb();
  DmCommon.Licence_OrderToHttp(Name);
end;

procedure TFMedFind.MenuItemOrderFreeClick(Sender: TObject);
begin
 ConnectToDb();
 DmCommon.Licence_OrderToHttp(Name, 1);
end;

procedure TFMedFind.MenuItemRefreshClick(Sender: TObject);
var
  Str: string;
begin
  ConnectToDb();

  Log('i', 'Завантаження ліцензій ...');
  fCodesLic := DmCommon.Licence_GetFromHttp(Name);
  SetComboBox(ComboBoxFirm, fCodesLic);
  if (fCodesLic.Count = 0) then
    Log('i', 'Не знайдено ліцензій')
  else begin
    Log('i', Format('Знайдено %d. Ліцензії для кодів %s', [fCodesLic.Count, fCodesLic.DelimitedText]));
    QueryCurOpen(GetParentQueryCur(), GetParentQueryPrev());
  end;

  Settings.SetItem('Licence', 'LastUpdate', DateTimeToStr(Now()));
end;

procedure TFMedFind.PageControlChange(Sender: TObject);
begin
  if (PageControl.ActivePage.Name = 'TabSheetPrev') and (ComboBoxFirm.Text = cChooseAll) then
  begin
    Log('i', 'Пропоновані звіти формуються тільки по ЄДРПОУ та періоду');
    if (ComboBoxFirm.CanFocus) then
        ComboBoxFirm.SetFocus();
  end;
end;

procedure TFMedFind.BitBtnPrintClick(Sender: TObject);
var
  PropGuard: TPropGuard;
begin
  if (GetParentQueryCur().RecordCount = 0) then
  begin
    Log('i', 'Немає даних для друку');
    Exit();
  end;

  PropGuard := TPropGuard.Create(GetParentHideFiealds(), 'Visible', False);
  try
    //FrPrintGrid1.Caption := Format('%s -- Період: %s %s року--Звіт: %s)',
    //  [cAppName, ComboBoxMonth.Text, ComboBoxYear.Text, ComboBoxDoc.Text]);

    //ResourceLoadReport('Report_FMedCheckDocs1', frReport1);
    FrPrintGrid1.OnGetValue := @FrPrintGrid1GetValue;
    FrPrintGrid1.Template := 'res\Report\CheckDocs2.lrf';
    if (not FileExists(FrPrintGrid1.Template)) then
    begin
      Log('e', 'Шаблон не існує ' + FrPrintGrid1.Template);
      Exit();
    end;

    FrPrintGrid1.PreviewReport();

    //ResourceLoadReport('Report_FMedCheckDocs1', frReport1);
    //frReport1.LoadFromFile('Res\Report\FMedCheckDocs1.lrf');
    //if (frReport1.PrepareReport()) then
    //  frReport1.ShowReport();
  finally
    PropGuard.Free();
  end;
end;

procedure TFMedFind.BitBtnRunMedClick(Sender: TObject);
var
  Path: string;
  JObj: TJSONObject;
begin
  JObj := GetCurPathObj();
  if (JObj.Get('port', 0) = 0) then
  begin
    Log('i', 'Не мережева версія програми');
    Disconnect();
    InitEmptyGrid(GetParentQueryCur());
  end;

  Path := ConcatPaths([ComboBoxPath.Text, 'ezvit.exe']);
  Log('i', 'Запуск програми ' + Path);
  ExecProcess(Path);
end;

procedure TFMedFind.InitEmptyGrid(aQuery: TSQLQuery);
var
  i: integer;
begin
  // Add cloumn visualisation in empty Grid
  for i := 0 to aQuery.Fields.Count - 1 do
    if (aQuery.Fields[i].Visible) then
      with DbGridCur.Columns.Add do
        FieldName := aQuery.Fields[i].DisplayLabel;
end;

procedure TFMedFind.InitMedControl();
var
  i: integer;
  Path, Port: string;
  BtnEnable: boolean;
  JObj: TJSONObject;
begin
  fJMedApp := MedIni.ToJson();
  for i := 0 to fJMedApp.Count - 1 do
  begin
    JObj := fJMedApp.Objects[i];
    Path := JObj.Get('path', '');
    Port := JObj.Get('port', '');
    ComboBoxPath.Items.AddObject(Path, JObj);
  end;

  BtnEnable := (fJMedApp.Count > 0);
  BitBtnRunMed.Enabled := BtnEnable;
  BitBtnFind.Enabled := BtnEnable;
  BitBtnActivation.Enabled := BtnEnable;
  BitBtnPrint.Enabled := BtnEnable;
end;

procedure TFMedFind.FormCreate(Sender: TObject);
var
  Str: string;
begin
  inherited;
  Str := '111   234 56 1  11'.TrimInt();

  SetFont(self);
  ProtectTimer.TimingStart();

  fCount := 0;
  fCurCaption := TabSheetCur.Caption;
  fPrevCaption := TabSheetPrev.Caption;
  fSortField := 'CARDSTATUS_NAME';
  fSortAsc := True;

  if (not MedIni.IsFile()) then
    MedIni.AddFromRegistry();
  InitMedControl();

  if (ComboBoxPath.Items.Count = 0) then
  begin
    Log('w', 'Неможливо знайти програму звітності');
    ComboBoxPath.Text :=  '';
    //Enabled := False;
  end else begin
    ComboBoxPath.ItemIndex := 0;
    SetEmbededPath(0);
  end;

  ComboBoxYearDropDown(nil);

  if (not Licence.IsFile()) then
    Log('w', 'Файл ліцензій не знайдено');

  fCodesLic := Licence.GetFirmCodes(Name);
  SetComboBox(ComboBoxFirm, fCodesLic);

  fDemoFields := TStringList.Create();
  fDemoFields.Add('CARDSTATUS_NAME');
  //fDemoFields.Add('MODDATE');
  fDemoFields.Add('CHARCODE');
  fDemoFields.Add('CARDSENDSTT_NAME');
  fDemoFields.Add('HZ');

  PanelComboBox.Font.Size := 10;

  InitEmptyGrid(GetParentQueryCur());

  StateStore.Load(self);
  StateStore.ComboBoxSetIndex([ComboBoxYear, ComboBoxMonth, ComboBoxDoc, ComboBoxFirm]);

  fColorYelow := RGBToColor(255, 255, 153);
  StateStore.SetCtrlColor(self, fColorYelow, 'edit');
  //StateStore.SetCtrlColor(self, clWhite, 'button');

  if (ProtectTimer.TimingCheck()) then
  begin
    ComboBoxMonth.Clear();
    fCodesLic.Clear();
  end;
end;

procedure TFMedFind.FormDestroy(Sender: TObject);
begin
  if (fCount > 0) then
    StateStore.Save(self);

  FreeAndNil(fJMedApp);
  FreeAndNil(fCodesLic);
  FreeAndNil(fTablesMain);
  FreeAndNil(fDemoFields);
  FreeAndNil(fJData);
end;

end.

