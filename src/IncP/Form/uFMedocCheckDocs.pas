unit uFMedocCheckDocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, SQLDB, Forms, Controls, Graphics, Dialogs, StdCtrls,
  DBGrids, ExtCtrls, LR_Class, DB,
  uDmFbConnect, uType, uGenericMatrix, uWinReg, uSys;

type

  { TFMedocCheckDocs }

  TFMedocCheckDocs = class(TForm)
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
    SQLQuery2: TSQLQuery;
    procedure ButtonExecClick(Sender: TObject);
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
  DmFbConnect.IBConnection1.Connected := False;
  DmFbConnect.IBConnection1.DatabaseName := ComboBoxPath.Text;
  DmFbConnect.IBConnection1.Connected := True;

  SQLQuery1.DataBase := DmFbConnect.IBConnection1;
  SQLQuery1.Transaction := DmFbConnect.SQLTransaction1;

  DmFbConnect.DataSource1.DataSet := SQLQuery1;
  DBGrid1.DataSource := DmFbConnect.DataSource1;
  DBGrid1.Visible := True;

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
  ComboBoxPath.Items.Assign(FindMedocDB());
  if (ComboBoxPath.Items.Count = 0) then
  begin
       ShowMessage('Бази МЕДОК не знайдено');
       Exit();
  end;

  ComboBoxPath.ItemIndex := 0;
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

procedure TFMedocCheckDocs.FormCreate(Sender: TObject);
var
  Path: String;
begin
  Path := 'C:\Program Files\Medoc\Medoc\fb3\32';
  SysPathAddd(Path);

  SetComboBoxToCurrentMonth(ComboBoxMonth);
  SetComboBoxToCurrentYear(ComboBoxYear);
end;

end.

