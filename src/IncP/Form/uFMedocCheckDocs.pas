// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils, SQLDB, Forms, Controls, Graphics, Dialogs,
  StdCtrls, DBGrids, Grids, ExtCtrls, DB, fpjson, jsonparser, uFLogin,
  uDmFbConnect, uLicence, uWinReg, uSys, uLog, uFormState;

type

  { TFMedocCheckDocs }
  TFMedocCheckDocs = class(TForm)
    ButtonGetLicense: TButton;
    ButtonOrderLicense: TButton;
    ButtonPrint: TButton;
    ButtonExec: TButton;
    ComboBoxFirm: TComboBox;
    ComboBoxPath: TComboBox;
    ComboBoxMonth: TComboBox;
    ComboBoxDoc: TComboBox;
    ComboBoxYear: TComboBox;
    DataSourceGrid: TDataSource;
    DataSourceCodes: TDataSource;
    DBGrid1: TDBGrid;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Panel1: TPanel;
    SQLQueryGrid: TSQLQuery;
    SQLQueryCodes: TSQLQuery;
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
    procedure ButtonGetLicenseClick(Sender: TObject);
    procedure ButtonOrderLicenseClick(Sender: TObject);
    procedure ComboBoxPathChange(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure DBGrid1TitleClick(Column: TColumn);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SQLQueryGridCalcFields(DataSet: TDataSet);
  private
    fSortField: string;
    fSortAsc: Boolean;
    fJMedocApp: TJSONArray;
    fFirmCodesLicensed: TStringList;
    fDemoFields: TStringList;
    procedure SetComboBoxToCurrentMonth(aComboBox: TComboBox);
    procedure SetComboBoxToCurrentYear(aComboBox: TComboBox);
    procedure SetComboBoxDoc();
    procedure QueryOpen();
    function  GetFirmCodes(): TStringList;
    procedure SetEmbededPath(aIdx: integer);
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

function TFMedocCheckDocs.GetFirmCodes(): TStringList;
var
  Str: String;
begin
  SQLQueryCodes.DataBase := DmFbConnect.IBConnection1;
  SQLQueryCodes.Transaction := DmFbConnect.SQLTransaction1;
  SQLQueryCodes.Open();

  Result := TStringList.Create();
  SQLQueryCodes.First();
  while not SQLQueryCodes.EOF do
  begin
    Str := SQLQueryCodes.FieldByName('EDRPOU').AsString;
    Result.Add(Str);
    SQLQueryCodes.Next();
  end;

  SQLQueryCodes.Close();
end;

procedure TFMedocCheckDocs.QueryOpen();
var
  Month, Year, Idx: Integer;
  Str: String;
  JObj: TJSONObject;
  Port: Integer;
  SF_HZ: TStringField;
begin
  DmFbConnect.IBConnection1.Connected := False;
  Idx := ComboBoxPath.ItemIndex;
  JObj := TJSONObject(ComboBoxPath.Items.Objects[Idx]);

  // якщо вказаний порт то версія мережна інакше embeded
  Port := JObj.Get('port', 0);
  if (Port > 0) then
  begin
    DmFbConnect.IBConnection1.HostName := 'localhost';
    DmFbConnect.IBConnection1.Port := Port;
    DmFbConnect.IBConnection1.UserName := 'SYSDBA';
    DmFbConnect.IBConnection1.Password := 'masterkey';
  end;
  DmFbConnect.IBConnection1.DatabaseName := JObj.Get('db', '');
  //DmFbConnect.IBConnection1.CharSet := 'UTF8';

  try
    DmFbConnect.IBConnection1.Connected := True;
  except
    on E: EDatabaseError do
    begin
      if Pos('used by another', LowerCase(E.Message)) > 0 then
        Log.Print('Процес занятий іншим користувачем')
      else
        raise;
    end;
  end;

  SQLQueryGrid.Close();
  //SQLQueryGrid.Fields.Clear();
  //SQLQueryGrid.FieldDefs.Clear();
  SQLQueryGrid.DataBase := DmFbConnect.IBConnection1;
  SQLQueryGrid.Transaction := DmFbConnect.SQLTransaction1;

  DBGrid1.Visible := True;

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
  //DBGrid1.OnDrawColumnCell := nil;

  SQLQueryGrid.Open();
end;

procedure TFMedocCheckDocs.ButtonExecClick(Sender: TObject);
var
  FirmCodes: TStringList;
begin
  QueryOpen();
end;

procedure TFMedocCheckDocs.ButtonGetLicenseClick(Sender: TObject);
var
  FirmCodes, FirmCodesLic: TStringList;
begin
  try
    Log.Print('Завантаження ліцензій ...');
    QueryOpen();
    FirmCodes := GetFirmCodes();
    Licence.HttpToFile(FirmCodes);
    if (Licence.LastErr <> '') then
       Log.Print('Помилка ' + Licence.LastErr)
    else begin
      FirmCodesLic := Licence.GetFirmCodes(Name);
      FirmCodesLic.Delimiter := ',';
      FirmCodesLic.StrictDelimiter := True;
      Log.Print('Знайдено ліцензії для кодів ' + FirmCodesLic.DelimitedText);
    end;
  finally
    FreeAndNil(FirmCodesLic);
    FirmCodes.Free();
  end;

  fFirmCodesLicensed := Licence.GetFirmCodes(Name);
end;

procedure TFMedocCheckDocs.ButtonOrderLicenseClick(Sender: TObject);
var
  AuthOk: boolean;
  FirmCodes: TStringList;
begin
   FirmCodes := nil;
   try
     FLogin.Caption := 'Активація програми';
     FLogin.EditUser.EditLabel.Caption := 'Дилер';
     FLogin.EditPassword.EditLabel.Caption := 'Ключ';
     if (FLogin.ShowModal = mrOk) then
     begin
       QueryOpen();
       FirmCodes := GetFirmCodes();
       AuthOk := Licence.OrderFromHttp(FirmCodes, Name, FLogin.EditUser.Text, FLogin.EditPassword.Text);
       if (AuthOk) then
         Log.Print('Запит на отримання ліцензій відправлено')
       else
         Log.Print('Помилка авторизації на сервері ліцензій');
     end;
     FLogin.Clear();
   finally
     FreeAndNil(FirmCodes);
   end;
end;

procedure TFMedocCheckDocs.ComboBoxPathChange(Sender: TObject);
begin
  SetEmbededPath(ComboBoxPath.ItemIndex)
end;

procedure TFMedocCheckDocs.DBGrid1DrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  Code: String;
  DisplayText: String;
begin
  Code := DBGrid1.DataSource.DataSet.FieldByName('EDRPOU').AsString;

  // Встановлюємо колір фону та шрифт
  with DBGrid1.Canvas do
  begin
    if gdSelected in State then
    begin
      Brush.Color := clYellow;
      Font.Color := clBlack;
    end else begin
      Brush.Color := DBGrid1.Color;
      Font.Color := DBGrid1.Font.Color;
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

procedure TFMedocCheckDocs.DBGrid1TitleClick(Column: TColumn);
var
   fld: string;
   s: TStringField;
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
    DBGrid1.Invalidate();
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
  SetComboBoxToCurrentYear(ComboBoxYear);
  SetComboBoxDoc();

  fFirmCodesLicensed := Licence.GetFirmCodes(Name);
  ComboBoxFirm.Items.Assign(fFirmCodesLicensed);
  ComboBoxFirm.Items.Insert(0, '');

  fDemoFields := TStringList.Create();
  fDemoFields.Add('CARDSTATUS_NAME');
  fDemoFields.Add('MODDATE');
  fDemoFields.Add('CHARCODE');
  fDemoFields.Add('CARDSENDSTT_NAME');

  Panel1.Font.Size := 10;
  FormStateRec.Load(self);
end;

procedure TFMedocCheckDocs.FormDestroy(Sender: TObject);
begin
  FormStateRec.Save(self);

  FreeAndNil(fJMedocApp);
  FreeAndNil(fFirmCodesLicensed);
end;

procedure TFMedocCheckDocs.SQLQueryGridCalcFields(DataSet: TDataSet);
var
   StrXML: String;
begin
  if (not DataSet.FieldByName('XMLVALS').IsNull) then
  begin
    StrXML := DataSet.FieldByName('XMLVALS').AsString;
  end;

  //HZ  := GetXmlValue(StrXML, 'HZ');
  //HZN := GetXmlValue(StrXML, 'HZN');
  //HZU := GetXmlValue(StrXML, 'HZU');
  //
  //// формуємо обчислене значення
  //DataSet.FieldByName('HZ_VALUE').AsString := HZ + ',' + HZN + ',' + HZU;
end;

end.

