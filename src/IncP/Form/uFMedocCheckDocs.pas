// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, SQLDB, Forms, Controls, Graphics, Dialogs,
  StdCtrls, DBGrids, Grids, ExtCtrls, LR_Class, DB, fpjson, jsonparser, uFLogin,
  uDmFbConnect, uType, uGenericMatrix, uLicence, uWinReg, uSys, uLog, uConst, uFormState;

type

  { TFMedocCheckDocs }

  TFMedocCheckDocs = class(TForm)
    ButtonGetLicense: TButton;
    ButtonOrderLicense: TButton;
    ButtonPrint: TButton;
    ButtonExec: TButton;
    ComboBoxPath: TComboBox;
    ComboBoxMonth: TComboBox;
    ComboBoxDoc: TComboBox;
    ComboBoxYear: TComboBox;
    DBGrid1: TDBGrid;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    SQLQuery1: TSQLQuery;
    SQLQueryCodes: TSQLQuery;
    procedure ButtonExecClick(Sender: TObject);
    procedure ButtonGetLicenseClick(Sender: TObject);
    procedure ButtonOrderLicenseClick(Sender: TObject);
    procedure ComboBoxPathChange(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SQLQuery1AfterOpen(DataSet: TDataSet);
  private
    JMedocApp: TJSONArray;
    FirmCodesLicensed: TStringList;
    procedure SetComboBoxToCurrentMonth(aComboBox: TComboBox);
    procedure SetComboBoxToCurrentYear(aComboBox: TComboBox);
    procedure QueryOpen();
    function  GetFirmCodes(): TStringList;
    procedure SetEmbededPath(aIdx: integer);
  public

  end;

var
  FMedocCheckDocs: TFMedocCheckDocs;

implementation

{$R *.lfm}

{ TFMedocCheckDocs }

procedure TFMedocCheckDocs.SetEmbededPath(aIdx: integer);
var
  JObj: TJSONObject;
  Path: string;
begin
  JObj := TJSONObject(ComboBoxPath.Items.Objects[aIdx]);
  Path := JObj.Strings['path']  + '\fb3\32';
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
  DmFbConnect.IBConnection1.DatabaseName := JObj.Get('db');
  //DmFbConnect.IBConnection1.CharSet := 'UTF8';
  DmFbConnect.IBConnection1.Connected := True;

  SQLQuery1.Close();
  SQLQuery1.DataBase := DmFbConnect.IBConnection1;
  SQLQuery1.Transaction := DmFbConnect.SQLTransaction1;

  DmFbConnect.DataSource1.DataSet := SQLQuery1;
  DBGrid1.DataSource := DmFbConnect.DataSource1;
  DBGrid1.Visible := True;

  Month := Integer(ComboBoxMonth.Items.Objects[ComboBoxMonth.ItemIndex]);
  Year := Integer(ComboBoxYear.Items.Objects[ComboBoxYear.ItemIndex]);
  Str := FormatDateTime('yyyy-mm-dd', EncodeDate(Year, Month, 1));
  SQLQuery1.MacroByName('_PERDATE').Value := QuotedStr(Str);

  Str := ComboBoxDoc.Items.Names[ComboBoxDoc.ItemIndex];
  SQLQuery1.ParamByName('_CHARCODE').Value := LowerCase(Str);

  SQLQuery1.Open();
end;


procedure TFMedocCheckDocs.SetComboBoxToCurrentMonth(aComboBox: TComboBox);
var
  i, Month: Integer;
begin
  aComboBox.Items.Clear();
  aComboBox.Items.AddObject('Січень', TObject(1));
  aComboBox.Items.AddObject('Лютий', TObject(2));
  aComboBox.Items.AddObject('Березень', TObject(3));
  //aComboBox.Items.AddObject('- 1 Квартал', TObject(101));
  //aComboBox.Items.AddObject('-- 1 Півріччя', TObject(1001));
  aComboBox.Items.AddObject('Квітень', TObject(4));
  aComboBox.Items.AddObject('Травень', TObject(5));
  aComboBox.Items.AddObject('Червень', TObject(6));
  //aComboBox.Items.AddObject('- 2 Квартал', TObject(102));
  aComboBox.Items.AddObject('Липень', TObject(7));
  aComboBox.Items.AddObject('Серпень', TObject(8));
  aComboBox.Items.AddObject('Вересень', TObject(9));
  //aComboBox.Items.AddObject('- 3 Квартал', TObject(103));
  aComboBox.Items.AddObject('Жовтень', TObject(10));
  aComboBox.Items.AddObject('Листопад', TObject(11));
  aComboBox.Items.AddObject('Грудень', TObject(12));
  //aComboBox.Items.AddObject('- 4 Квартал', TObject(104));
  //aComboBox.Items.AddObject('-- 2 Півріччя', TObject(1002));
  //aComboBox.Items.AddObject('--- Рік', TObject(10000));

  Month := MonthOf(IncMonth(Date, -1));

  for i := 0 to aComboBox.Items.Count - 1 do
  begin
    if Integer(aComboBox.Items.Objects[i]) = Month then
    begin
      aComboBox.ItemIndex := i;
      Exit;
    end;
  end;
end;

procedure TFMedocCheckDocs.SetComboBoxToCurrentYear(aComboBox: TComboBox);
const
  YearsBack: integer = 2;
var
  i, Year: Integer;
begin
  Year := YearOf(IncMonth(Date, -1));

  aComboBox.Items.Clear();
  for i := Year - YearsBack to Year + 1 do
    aComboBox.Items.AddObject(IntToStr(i), TObject(i));

  aComboBox.ItemIndex := YearsBack;
end;

procedure TFMedocCheckDocs.SQLQuery1AfterOpen(DataSet: TDataSet);
var
  i, Idx: Integer;
  Data: array of TStringArray;
  Matrix: TStringMatrix;
begin
  Data := [
    ['EDRPOU', 'ЄДРПОУ', '70'],
    ['SHORTNAME', 'Назва', '250'],
    ['NAME', 'Найменування', '250'],
    ['VAT', 'Тип', '50'],
    ['PERDATE', 'Період', '80'],
    ['DEPT', 'Філія', '80'],
    ['MODDATE', 'Змінено', '80'],
    ['STATUSNAME', 'Статус', '100'],
    ['CHARCODE', 'Код звіту', '60']
  ];

  try
    Matrix := TStringMatrix.Create();
    Matrix.AddMatrix(Data);

    for i := 0 to DBGrid1.Columns.Count - 1 do
    begin
      Idx := Matrix.Find(0, 0, DBGrid1.Columns[i].FieldName);
      if Idx >= 0 then
      begin
        DBGrid1.Columns[i].Width := StrToInt(Matrix.Cells[Idx, 2]);
        DBGrid1.Columns[i].Title.Caption := Matrix.Cells[Idx, 1];
      end
      else
          DBGrid1.Columns[i].Width := 100;
    end;
  finally
    Matrix.Free();
  end;
end;

procedure TFMedocCheckDocs.ButtonExecClick(Sender: TObject);
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
    if ((Column.FieldName = 'STATUSNAME') or (Column.FieldName = 'NAME')) and (FirmCodesLicensed.IndexOf(Code) = -1) then
      DisplayText := 'Д Е М О'
    else
      DisplayText := Column.Field.DisplayText;

    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, DisplayText);
  end;
end;

procedure TFMedocCheckDocs.FormCreate(Sender: TObject);
var
  i: integer;
  JObj: TJSONObject;
begin
  JMedocApp := RegFindMedocInfo();
  for i := 0 to JMedocApp.Count - 1 do
  begin
    JObj := JMedocApp.Objects[i];
    ComboBoxPath.Items.AddObject(JObj.Get('db'), JObj);
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

  ComboBoxDoc.Items.AddPair('J0200126', 'Податкова декларація з податку на додану вартість');
  ComboBoxDoc.Items.AddPair('J0500110', 'Податковий розрахунок сум доходу ... ЄСВ');
  ComboBoxDoc.ItemIndex := 0;

  FirmCodesLicensed := Licence.GetFirmCodes(Name);

  FormStateRec.Load(self);
end;

procedure TFMedocCheckDocs.FormDestroy(Sender: TObject);
begin
  FormStateRec.Save(self);

  FreeAndNil(JMedocApp);
  FreeAndNil(FirmCodesLicensed);
end;

end.

