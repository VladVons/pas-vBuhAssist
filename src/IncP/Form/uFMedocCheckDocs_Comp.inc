procedure TFMedocCheckDocs.SetComboBoxToCurrentMonth(aComboBox: TComboBox);
var
  i, Month: Integer;
begin
  aComboBox.Items.Clear();
  aComboBox.Items.AddObject('- Всі', TObject(401));
  aComboBox.Items.AddObject('Січень', TObject(1));
  aComboBox.Items.AddObject('Лютий', TObject(2));
  aComboBox.Items.AddObject('Березень', TObject(3));
  aComboBox.Items.AddObject('- I Квартал', TObject(101));
  aComboBox.Items.AddObject('- I Півріччя', TObject(201));
  aComboBox.Items.AddObject('Квітень', TObject(4));
  aComboBox.Items.AddObject('Травень', TObject(5));
  aComboBox.Items.AddObject('Червень', TObject(6));
  aComboBox.Items.AddObject('- II Квартал', TObject(102));
  aComboBox.Items.AddObject('Липень', TObject(7));
  aComboBox.Items.AddObject('Серпень', TObject(8));
  aComboBox.Items.AddObject('Вересень', TObject(9));
  aComboBox.Items.AddObject('- III Квартал', TObject(103));
  aComboBox.Items.AddObject('Жовтень', TObject(10));
  aComboBox.Items.AddObject('Листопад', TObject(11));
  aComboBox.Items.AddObject('Грудень', TObject(12));
  aComboBox.Items.AddObject('- IV Квартал', TObject(104));
  aComboBox.Items.AddObject('- II Півріччя', TObject(202));
  aComboBox.Items.AddObject('- Рік', TObject(301));

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
var
  i, YearNext: Integer;
begin
  YearNext := YearOf(IncYear(Date(), 1));
  if (aYear = 0) then
    aYear := YearOf(IncYear(Date(), -cYearsBack));
  aYear := Max(aYear, YearNext - 15);

  aComboBox.Items.Clear();
  for i := aYear to YearNext do
    aComboBox.Items.AddObject(IntToStr(i), TObject(i));
end;

procedure TFMedocCheckDocs.SetComboBoxDoc();
begin
  ComboBoxDoc.Items.AddPair('', '');
  ComboBoxDoc.Items.AddPair('FJ-0200126', 'Податкова декларація з податку на додану вартість');
  ComboBoxDoc.Items.AddPair('FJ-0500110', 'Податковий розрахунок сум доходу ... ЄСВ');
  ComboBoxDoc.Items.AddPair('FJ-0209513', 'Податкова декларація акцизного податку');
  ComboBoxDoc.ItemIndex := 0;
end;

