// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils, SQLDB, Forms, Graphics,
  StdCtrls, DBGrids, Grids, ExtCtrls, DB, fpjson,
  uSys, uLog, uLicence, uWinReg, uFormState, uMedoc,
  uDmCommon;

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
    s: TDBGrid;
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
    procedure ButtonExecClick(Sender: TObject);
    procedure ButtonGetLicenceClick(Sender: TObject);
    procedure ButtonOrderLicenceClick(Sender: TObject);
    procedure ComboBoxPathChange(Sender: TObject);
    procedure ComboBoxYearDropDown(Sender: TObject);
    procedure sDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure sTitleClick(Column: TColumn);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SQLQueryGridCalcFields(DataSet: TDataSet);
  private
    fSortField: string;
    fSortAsc: Boolean;
    fJMedocApp: TJSONArray;
    fFirmCodesLicensed, fTablesMain, fDemoFields: TStringList;
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
begin
  if (not DmCommon.IBConnection.Connected) then
  begin
    Idx := ComboBoxPath.ItemIndex;
    JObj := TJSONObject(ComboBoxPath.Items.Objects[Idx]);
    DmCommon.Connect(JObj.Get('db', ''), JObj.Get('port', 0));

    fTablesMain := DmCommon.GetTablesMain();
  end;
end;

procedure TFMedocCheckDocs.QueryOpen();
var
  Month, Year: Integer;
  Str: String;
begin
  SQLQueryGrid.Close();
  SQLQueryGrid.DataBase := DmCommon.IBConnection;
  SQLQueryGrid.Transaction := DmCommon.SQLTransaction;

  s.Columns.Clear();
  s.Visible := True;

  Month := Integer(ComboBoxMonth.Items.Objects[ComboBoxMonth.ItemIndex]);
  Year := Integer(ComboBoxYear.Items.Objects[ComboBoxYear.ItemIndex]);
  Str := FormatDateTime('yyyy-mm-dd', EncodeDate(Year, Month, 1));
  SQLQueryGrid.MacroByName('_PERDATE').Value := QuotedStr(Str);

  Str := ComboBoxDoc.Items.Names[ComboBoxDoc.ItemIndex];
  SQLQueryGrid.ParamByName('_CHARCODE').Value := LowerCase(Str);

  SQLQueryGrid.MacroByName('_Order').Value := fSortField;
  SQLQueryGrid.MacroByName('_Asc').Value := IfThen(fSortAsc, 'ASC', 'DESC');;

  Str := '';
  if (ComboBoxFirm.Text <> '') then
    Str := ' AND ORG.EDRPOU=' + TRim(ComboBoxFirm.Text);
  SQLQueryGrid.MacroByName('_COND_ORG').Value := Str;

  //SQLQueryGrid.AfterOpen := nil;
  //SQLQueryGrid.OnCalcFields := nil;
  //SQLQueryGrid.AfterScroll := nil;
  //s.OnDrawColumnCell := nil;

  SQLQueryGrid.Open();
end;

procedure TFMedocCheckDocs.SQLQueryGridCalcFields(DataSet: TDataSet);
begin
  if (not DataSet.FieldByName('XMLVALS').IsNull) then
    DataSet.FieldByName('HZ').AsString := GetHzHuman(DataSet.FieldByName('XMLVALS').AsString);
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

procedure TFMedocCheckDocs.sDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  Code: String;
  DisplayText: String;
begin
  Code := s.DataSource.DataSet.FieldByName('EDRPOU').AsString;

  // Встановлюємо колір фону та шрифт
  with s.Canvas do
  begin
    if gdSelected in State then
    begin
      Brush.Color := clYellow;
      Font.Color := clBlack;
    end else begin
      Brush.Color := s.Color;
      Font.Color := s.Font.Color;
    end;
    FillRect(Rect); // малюємо фон

    // Вибираємо, який текст малювати
    if (fDemoFields.IndexOf(Column.FieldName) <> -1) and (fFirmCodesLicensed.IndexOf(Code) = -1) then
      DisplayText := 'Д Е М О'
    else
      DisplayText := Column.Field.DisplayText;

    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, DisplayText);
  end;
end;

procedure TFMedocCheckDocs.sTitleClick(Column: TColumn);
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
    s.Invalidate();
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
    ComboBoxPath.Items.AddObject(JObj.Get('db', ''), JObj);
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
  fDemoFields.Add('MODDATE');
  fDemoFields.Add('CHARCODE');
  fDemoFields.Add('CARDSENDSTT_NAME');
  fDemoFields.Add('HZ');

  // Add cloumn visualisation in empty Grid
  for i := 0 to SQLQueryGrid.Fields.Count - 1 do
    with s.Columns.Add do
      FieldName := SQLQueryGrid.Fields[i].DisplayLabel;

  Panel1.Font.Size := 10;
  FormStateRec.Load(self);
end;

procedure TFMedocCheckDocs.FormDestroy(Sender: TObject);
begin
  FormStateRec.Save(self);

  FreeAndNil(fJMedocApp);
  FreeAndNil(fFirmCodesLicensed);
end;

end.

