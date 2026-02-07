unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, SQLDB, Forms, Controls, Graphics, Dialogs, StdCtrls,
  DBGrids, ExtCtrls, LR_Class, DB,
  uDmFbConnect, uLicence, uType, uGenericMatrix, uWinReg;

type

  { TFMedocCheckDocs }

  TFMedocCheckDocs = class(TForm)
    ComboBox1: TComboBox;
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
    procedure ComboBox1Change(Sender: TObject);
    procedure ComboBoxMonthChange(Sender: TObject);
    procedure ComboBoxYearChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SQLQuery1AfterOpen(DataSet: TDataSet);
  private
    procedure SetComboBoxToCurrentMonth(aComboBox: TComboBox);
    procedure SetComboBoxToCurrentYear(aComboBox: TComboBox);
    procedure QueryOpen();
  public

  end;

var
  FMedocCheckDocs: TFMedocCheckDocs;

implementation

{$R *.lfm}

{ TFMedocCheckDocs }

procedure TFMedocCheckDocs.QueryOpen();
var
  Month, Year: Integer;
  Date: String;
begin
  Month := Integer(ComboBoxMonth.Items.Objects[ComboBoxMonth.ItemIndex]);
  Year := Integer(ComboBoxYear.Items.Objects[ComboBoxYear.ItemIndex]);
  Date := FormatDateTime('yyyy-mm-dd', EncodeDate(Year, Month, 1));
  SQLQuery1.MacroByName('_PERDATE').Value := QuotedStr(Date);
  SQLQuery1.Close();
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
  aComboBox.Items.AddObject('- 1 Квартал', TObject(101));
  aComboBox.Items.AddObject('-- 1 Півріччя', TObject(1001));
  aComboBox.Items.AddObject('Квітень', TObject(4));
  aComboBox.Items.AddObject('Травень', TObject(5));
  aComboBox.Items.AddObject('Червень', TObject(6));
  aComboBox.Items.AddObject('- 2 Квартал', TObject(102));
  aComboBox.Items.AddObject('Липень', TObject(7));
  aComboBox.Items.AddObject('Серпень', TObject(8));
  aComboBox.Items.AddObject('Вересень', TObject(9));
  aComboBox.Items.AddObject('- 3 Квартал', TObject(103));
  aComboBox.Items.AddObject('Жовтень', TObject(10));
  aComboBox.Items.AddObject('Листопад', TObject(11));
  aComboBox.Items.AddObject('Грудень', TObject(12));
  aComboBox.Items.AddObject('- 4 Квартал', TObject(104));
  aComboBox.Items.AddObject('-- 2 Півріччя', TObject(1002));
  aComboBox.Items.AddObject('--- Рік', TObject(10000));

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

procedure TFMedocCheckDocs.FormShow(Sender: TObject);
begin
  ComboBox1.Items.Assign(FindMedocDB());
  if (ComboBox1.Items.Count = 0) then
  begin
       ShowMessage('Бази МЕДОК не знайдено');
       Exit();
  end;

  ComboBox1.ItemIndex := 0;
  ComboBox1Change(Nil);
end;

procedure TFMedocCheckDocs.SQLQuery1AfterOpen(DataSet: TDataSet);
var
  i, Idx: Integer;
  Matrix: TStringMatrix;
begin
  Matrix := TStringMatrix.Create();
  Matrix.Add(['EDRPOU', 'ЄДРПОУ', '70']);
  Matrix.Add(['SHORTNAME', 'Назва', '250']);
  Matrix.Add(['VAT', 'Тип', '50']);
  Matrix.Add(['PERDATE', 'Період', '80']);
  Matrix.Add(['MODDATE', 'Змінено', '80']);
  Matrix.Add(['STATUSNAME', 'Статус', '100']);
  Matrix.Add(['CHARCODE', 'Код звіту', '60']);

  try
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

procedure TFMedocCheckDocs.ComboBox1Change(Sender: TObject);
begin
  DmFbConnect.IBConnection1.Connected := False;
  DmFbConnect.IBConnection1.DatabaseName := ComboBox1.Text;
  DmFbConnect.IBConnection1.Connected := True;

  SQLQuery1.DataBase := DmFbConnect.IBConnection1;
  SQLQuery1.Transaction := DmFbConnect.SQLTransaction1;

  DmFbConnect.DataSource1.DataSet := SQLQuery1;
  DBGrid1.DataSource := DmFbConnect.DataSource1;

  QueryOpen();
end;

procedure TFMedocCheckDocs.ComboBoxMonthChange(Sender: TObject);
begin
  QueryOpen();
end;

procedure TFMedocCheckDocs.ComboBoxYearChange(Sender: TObject);
begin
  QueryOpen();
end;

procedure TFMedocCheckDocs.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  SetComboBoxToCurrentMonth(ComboBoxMonth);
  SetComboBoxToCurrentYear(ComboBoxYear);
end;

//procedure TFMedocCheckDocs.FormCreate(Sender: TObject);
//var
//  Firms, Db: TStringList;
//  StringMatrix, StringMatrix2: TStringMatrix;
//begin
//  Firms := TStringList.Create();
//  StringMatrix := FindMedocDB();
//  Firms := Nil;
//
//  StringMatrix := TStringMatrix.Create();
//
//  StringMatrix.AddMatrix(
//    [
//      ['one', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'],
//      ['two', '1111111111111111111111111111111']
//    ]
//    );
//  MatrixCryptToFile('lic.dat', '123', StringMatrix);
//  StringMatrix2 := MatrixCryptFromFile('lic.dat', '123');
//
//  Firms := TStringList.Create();
//  Firms.AddStrings(['88888801']);
//  GetLicence(Firms);
//
//
//  SQLQuery1.DataBase := DmFbConnect.IBConnection1;
//  SQLQuery1.Transaction := DmFbConnect.SQLTransaction1;
//  //SQLQuery1.SQL.Text := 'SELECT EDRPOU, SHORTNAME, INDTAXNUM, DEPT FROM ORG';
//
//  DmFbConnect.DataSource1.DataSet := SQLQuery1;
//  DBGrid1.DataSource := DmFbConnect.DataSource1;
//
//  SQLQuery1.Open();
//end;

end.

