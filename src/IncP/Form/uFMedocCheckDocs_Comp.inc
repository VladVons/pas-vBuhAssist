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

  Month := MonthOf(IncMonth(Date(), -1));

  for i := 0 to aComboBox.Items.Count - 1 do
  begin
    if Integer(aComboBox.Items.Objects[i]) = Month then
    begin
      aComboBox.ItemIndex := i;
      Exit;
    end;
  end;
end;

procedure TFMedocCheckDocs.SetComboBoxToYear(aComboBox: TComboBox; aYear: Integer = 0);
const
  YearsBack: integer = 2;
var
  i: Integer;
begin
  if (aYear = 0) then
    aYear := YearOf(IncMonth(Date(), -1));

  aComboBox.Items.Clear();
  for i := aYear - YearsBack to aYear + 1 do
    aComboBox.Items.AddObject(IntToStr(i), TObject(i));

  aComboBox.ItemIndex := YearsBack;
end;

procedure TFMedocCheckDocs.SetComboBoxDoc();
begin
  ComboBoxDoc.Items.AddPair('J0200126', 'Податкова декларація з податку на додану вартість');
  ComboBoxDoc.Items.AddPair('J0500110', 'Податковий розрахунок сум доходу ... ЄСВ');
  ComboBoxDoc.Items.AddPair('J0209513', 'Податкова декларація акцизного податку');
  ComboBoxDoc.ItemIndex := 0;
end;

