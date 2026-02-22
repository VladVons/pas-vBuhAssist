// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils, SQLDB, Forms, Graphics, StdCtrls,
  DBGrids, Grids, ExtCtrls, Buttons, LR_Class, LR_DBSet, LR_PGrid, DB, fpjson,
  uSys, uLog, uLicence, uWinReg, uFormState, uQuery, uMedoc, uDmCommon;

type

  { TFMedocCheckDocs }
  TFMedocCheckDocs = class(TForm)
    ButtonGetLicence: TButton;
    ButtonOrderLicence: TButton;
    ButtonPrint: TButton;
    ButtonExec: TButton;
    ComboBoxFirm: TComboBox;
    ComboBoxPath: TComboBox;
    ComboBoxMonth: TComboBox;
    ComboBoxDoc: TComboBox;
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
    Panel1: TPanel;
    SQLQueryGrid: TSQLQuery;
    SQLQueryGridCARDSENDSTT_NAME: TStringField;
    SQLQueryGridCHARCODE: TStringField;
    SQLQueryGridDEPT: TStringField;
    SQLQueryGridEDRPOU: TStringField;
    SQLQueryGridHZ: TStringField;
    SQLQueryGridINDTAXNUM: TStringField;
    SQLQueryGridMODDATE: TDateTimeField;
    SQLQueryGridPERDATE: TDateField;
    SQLQueryGridSHORTNAME: TStringField;
    SQLQueryGridCARDSTATUS_NAME: TStringField;
    SQLQueryGridVAT: TStringField;
    SQLQueryGridXMLVALS: TBlobField;
    SQLQueryGridFJ: TStringField;
    procedure ButtonExecClick(Sender: TObject);
    procedure ButtonGetLicenceClick(Sender: TObject);
    procedure ButtonOrderLicenceClick(Sender: TObject);
    procedure ButtonPrintClick(Sender: TObject);
    procedure ComboBoxPathChange(Sender: TObject);
    procedure ComboBoxYearDropDown(Sender: TObject);
    procedure DbGridDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure DbGridTitleClick(Column: TColumn);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SQLQueryGridCalcFields(DataSet: TDataSet);
  private
    fSortField: string;
    fSortAsc: Boolean;
    fJMedocApp: TJSONArray;
    fFirmCodesLicensed, fTablesMain, fDemoFields: TStringList;
    fColorYelow: TColor;
    procedure SetComboBoxToCurrentMonth(aComboBox: TComboBox);
    procedure SetComboBoxToYear(aComboBox: TComboBox; aYear: Integer = 0);
    procedure SetComboBoxDoc();
    procedure QueryOpen();
    procedure SetEmbededPath(aIdx: integer);
    procedure ConnectToDb();
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

procedure TFMedocCheckDocs.ConnectToDB();
var
  Idx: Integer;
  JObj: TJSONObject;
  DbName: String;
begin
  Idx := ComboBoxPath.ItemIndex;
  JObj := TJSONObject(ComboBoxPath.Items.Objects[Idx]);
  DbName := JObj.Get('db', '');
  if (not DmCommon.IBConnection.Connected) or (DmCommon.IBConnection.DatabaseName <> DbName) then
  begin
    DmCommon.Connect(DbName, JObj.Get('port', 0));
    fTablesMain := DmCommon.GetTablesMain();
  end;
end;

procedure TFMedocCheckDocs.QueryOpen();
var
  Month, Year: Integer;
  Str, StrDb, StrMacro: String;
begin
  SQLQueryGrid.Close();
  SQLQueryGrid.DataBase := DmCommon.IBConnection;
  SQLQueryGrid.Transaction := DmCommon.SQLTransaction;

  DbGrid.Columns.Clear();
  DbGrid.Visible := True;

  Month := Integer(ComboBoxMonth.Items.Objects[ComboBoxMonth.ItemIndex]);
  Year := Integer(ComboBoxYear.Items.Objects[ComboBoxYear.ItemIndex]);
  Str := FormatDateTime('yyyy-mm-dd', EncodeDate(Year, Month, 1));
  SQLQueryGrid.MacroByName('_PERDATE').Value := QuotedStr(Str);

  Str := ComboBoxDoc.Items.Names[ComboBoxDoc.ItemIndex];
  SQLQueryGrid.ParamByName('_CHARCODE').Value := LowerCase(Str);

  SQLQueryGrid.MacroByName('_ORDER').Value := fSortField;
  SQLQueryGrid.MacroByName('_ASC').Value := IfThen(fSortAsc, 'ASC', 'DESC');

  Str := '';
  if (ComboBoxFirm.Text <> '') then
    Str := ' AND ORG.EDRPOU=' + TRim(ComboBoxFirm.Text);
  SQLQueryGrid.MacroByName('_COND_ORG').Value := Str;

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

  //SQLQueryGrid.AfterOpen := nil;
  //SQLQueryGrid.OnCalcFields := nil;
  //SQLQueryGrid.AfterScroll := nil;
  //DbGrid.OnDrawColumnCell := nil;

  //Str := ExpandSQL(SQLQueryGrid);
  //Log.Print(Str);
  SQLQueryGrid.Open();
end;

procedure TFMedocCheckDocs.SQLQueryGridCalcFields(DataSet: TDataSet);
var
  i: Integer;
  FieldXML, FieldFJ, FieldHZ, FieldCode: TField;
  Code: String;
begin
  FieldXML := DataSet.FieldByName('XMLVALS');
  FieldFJ := DataSet.FieldByName('FJ');
  FieldHZ := DataSet.FieldByName('HZ');
  if (not FieldXML.IsNull) and (not FieldXML.AsString.IsEmpty()) then
    FieldHZ.AsString := GetHzXml(FieldXML.AsString)
  else if (not FieldFJ.AsString.IsEmpty()) then
    FieldHZ.AsString := GetHzStr(FieldFJ.AsString);

  Code := DataSet.FieldByName('EDRPOU').AsString;
  if (fFirmCodesLicensed.IndexOf(Code) = -1) then
  begin
    for i := 0 to fDemoFields.Count - 1 do
      DataSet.FieldByName(fDemoFields[i]).AsString := 'ДЕМО';
  end;
end;

procedure TFMedocCheckDocs.ButtonExecClick(Sender: TObject);
begin
  ConnectToDb();
  QueryOpen();
end;

procedure TFMedocCheckDocs.ComboBoxPathChange(Sender: TObject);
begin
  SetEmbededPath(ComboBoxPath.ItemIndex)
end;

procedure TFMedocCheckDocs.ComboBoxYearDropDown(Sender: TObject);
var
  Val: Integer;
begin
  Val := FormStateRec.GetItem('FSettings', 'SpinEditBeginYear_Value', 0);
  SetComboBoxToYear(ComboBoxYear, Val);
end;

procedure TFMedocCheckDocs.DbGridDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  Code: String;
  DisplayText: String;
begin
  Code := DbGrid.DataSource.DataSet.FieldByName('EDRPOU').AsString;

  // Встановлюємо колір фону та шрифт
  with DbGrid.Canvas do
  begin
    if gdSelected in State then
    begin
      Brush.Color := RGBToColor(254, 240, 120);
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

procedure TFMedocCheckDocs.ButtonGetLicenceClick(Sender: TObject);
begin
  ConnectToDb();
  fFirmCodesLicensed := DmCommon.Licence_GetFromHttp();
end;

procedure TFMedocCheckDocs.ButtonOrderLicenceClick(Sender: TObject);
begin
  ConnectToDb();
  DmCommon.Licence_OrderToHttp();
end;

procedure TFMedocCheckDocs.ButtonPrintClick(Sender: TObject);
var
  i: Integer;
begin
  if (SQLQueryGrid.RecordCount = 0) then
  begin
    Log.Print('Немає даних для друку');
    Exit;
  end;

  FrPrintGrid1.PreviewReport();
  //frReport1.LoadFromFile('Report\FMedocCheckDocs1.lrf');
  //if (frReport1.PrepareReport()) then
  //  frReport1.ShowReport();
end;

procedure TFMedocCheckDocs.FormCreate(Sender: TObject);
var
  i: integer;
  JObj: TJSONObject;
begin
  fSortField := 'CARDSTATUS_NAME';
  fSortAsc := True;

  fJMedocApp := RegFindMedocInfo();
  for i := 0 to fJMedocApp.Count - 1 do
  begin
    JObj := fJMedocApp.Objects[i];
    ComboBoxPath.Items.AddObject(JObj.Get('path', ''), JObj);
  end;

  if (ComboBoxPath.Items.Count = 0) then
  begin
     Log.Print('Неможливо знайти програму звітності. Зверніться до свого дилера');
     ComboBoxPath.Text := '';
     Enabled := False;
  end else begin
     ComboBoxPath.ItemIndex := 0;
     SetEmbededPath(0);
  end;

  SetComboBoxToCurrentMonth(ComboBoxMonth);
  SetComboBoxToYear(ComboBoxYear);
  SetComboBoxDoc();

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
    with DbGrid.Columns.Add do
      if (SQLQueryGrid.Fields[i].Visible) then
        FieldName := SQLQueryGrid.Fields[i].DisplayLabel;

  Panel1.Font.Size := 10;
  FormStateRec.Load(self);

  fColorYelow := RGBToColor(255, 255, 153);
  FormStateRec.SetCtrlColor(self, fColorYelow, 'edit');
  //FormStateRec.SetCtrlColor(self, clWhite, 'button');
end;

procedure TFMedocCheckDocs.FormDestroy(Sender: TObject);
begin
  FormStateRec.Save(self);

  FreeAndNil(fJMedocApp);
  FreeAndNil(fFirmCodesLicensed);
end;

end.

