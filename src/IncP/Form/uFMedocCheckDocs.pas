unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, SQLDB, Forms, Controls, Graphics, Dialogs, StdCtrls,
  DBGrids, ExtCtrls, LR_Class, DB, fpjson, jsonparser,
  uFLogin, uDmFbConnect, uType, uGenericMatrix, uLicence, uWinReg, uSys, uLog, uConst, Grids;

type

  { TFMedocCheckDocs }

  TFMedocCheckDocs = class(TForm)
    ButtonGetLicense: TButton;
    ButtonPrint: TButton;
    ButtonExec: TButton;
    ComboBoxPath: TComboBox;
    ComboBoxMonth: TComboBox;
    ComboBoxDoc: TComboBox;
    ComboBoxYear: TComboBox;
    DBGrid1: TDBGrid;
    frReport1: TfrReport;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    SQLQuery1: TSQLQuery;
    SQLQueryCodes: TSQLQuery;
    procedure ButtonExecClick(Sender: TObject);
    procedure ButtonGetLicenseClick(Sender: TObject);
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
    function GetFirmCodesLicensed(): TStringList;
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
  SysPathAddd(Path);
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

function TFMedocCheckDocs.GetFirmCodesLicensed(): TStringList;
var
  i, Idx: integer;
  Code: String;
  FirmCodes: TStringList;
  Matrix: TStringMatrix;
begin
  try
    Matrix := MatrixCryptFromFile(cFileLic, cFileLicPassw);
    Result := TStringListEx.Create(Matrix.ColExport(0));

    FirmCodes := GetFirmCodes();
    for i := 0 to FirmCodes.Count - 1 do
    begin
      Code := FirmCodes[i];
      Idx := Result.IndexOf(Code);
      if (Idx = -1) and (Result.Count < cMaxLicensesFree) then
      begin
         Result.Add(Code);
      end;
    end;
  finally
    Matrix.Free();
    FirmCodes.Free();
  end;
end;

procedure TFMedocCheckDocs.QueryOpen();
var
  Month, Year: Integer;
  Str: String;
  JObj: TJSONObject;
  Port: Integer;
begin
  DmFbConnect.IBConnection1.Connected := False;
  JObj := TJSONObject(ComboBoxPath.Items.Objects[ComboBoxPath.ItemIndex]);

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
  DmFbConnect.IBConnection1.Connected := True;

  if (FirmCodesLicensed.Count = 0) then
    FirmCodesLicensed := GetFirmCodesLicensed();

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
  i, currentMonth: Integer;
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

  currentMonth := MonthOf(Date());  // 1..12

  for i := 0 to aComboBox.Items.Count - 1 do
  begin
    if Integer(aComboBox.Items.Objects[i]) = currentMonth then
    begin
      aComboBox.ItemIndex := i;
      Exit;
    end;
  end;
end;

procedure TFMedocCheckDocs.SetComboBoxToCurrentYear(aComboBox: TComboBox);
var
  i, currentYear: Integer;
begin
  aComboBox.Items.Clear();
  currentYear := YearOf(Now());

  // Додаємо 3 роки назад
  for i := currentYear - 3 to currentYear + 1 do
  begin
    aComboBox.Items.AddObject(IntToStr(i), TObject(i));
  end;

  aComboBox.ItemIndex := 3; // індекс поточного року
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
    ['VAT', 'Тип', '50'],
    ['PERDATE', 'Період', '80'],
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
  FirmCodes: TStringList;
  Matrix: TStringMatrix;
  Str: String;
begin
   FLogin.Caption := 'Авторизація дилера';
   if (FLogin.ShowModal = mrOk) then
   begin
     if (LeftStr(FLogin.Password.Text, 4) = 'med_') then
     begin
       QueryOpen();
       FirmCodes := GetFirmCodes();
       Matrix := GetLicenceFromHttp(FirmCodes, 'MedocCheckDoc', FLogin.User.Text);
       Log.Print('Запит на отримання ліцензій відправлено');
     end
     else
         Log.Print('Не вірний пароль');
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
begin
    // Малюємо стандартний фон
    DBGrid1.Canvas.FillRect(Rect);

    Code := DBGrid1.DataSource.DataSet.FieldByName('EDRPOU').AsString;
    if ((Column.FieldName = 'STATUSNAME') or (Column.FieldName = 'NAME')) and (FirmCodesLicensed.IndexOf(Code) = -1) then
      DBGrid1.Canvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 2, 'д е м о')
    else
      DBGrid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

procedure TFMedocCheckDocs.FormCreate(Sender: TObject);
var
  i: integer;
  JObj: TJSONObject;
begin
  JMedocApp := GetMedocInfoFromReg();
  for i := 0 to JMedocApp.Count - 1 do
  begin
    JObj := JMedocApp.Objects[i];
    ComboBoxPath.Items.AddObject(JObj.Get('db'), JObj);
  end;

  if (ComboBoxPath.Items.Count = 0) then
  begin
     Log.Print('Бази МЕДОК не знайдено');
     ComboBoxPath.Text := '';
     Enabled := False;
  end
  else
  begin
     ComboBoxPath.ItemIndex := 0;
     SetEmbededPath(0);
  end;

  SetComboBoxToCurrentMonth(ComboBoxMonth);
  SetComboBoxToCurrentYear(ComboBoxYear);

  ComboBoxDoc.Items.AddPair('J0200126', 'Податкова декларація з податку на додану вартість');
  ComboBoxDoc.Items.AddPair('J0500110', 'Податковий розрахунок сум доходу ... ЄСВ');
  ComboBoxDoc.ItemIndex := 0;

  FirmCodesLicensed := TStringList.Create();
end;

procedure TFMedocCheckDocs.FormDestroy(Sender: TObject);
begin
  JMedocApp.Free();
  FirmCodesLicensed.Free();
end;

end.

