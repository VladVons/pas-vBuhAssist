unit uPDF;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fppdf;

procedure TextToPDF(const aFileName: string; const aText: TStringList);

implementation

procedure TextToPDF(const aFileName: string; const aText: TStringList);
var
  Doc: TPDFDocument;
  Section: TPDFSection;
  Page: TPDFPage;
  FontIdx: Integer;
  i, Y: Integer;
begin
  Doc := TPDFDocument.Create(nil);
  try
    // Метадані
    //Doc.Infos.Title := 'Text to PDF Example';
    //Doc.Infos.Author := 'Lazarus 4.4 / FPC 3.2.2';
    //Doc.Infos.Producer := 'fcl-pdf';
    //Doc.Infos.ApplicationName := 'TextToPDF';
    //Doc.Infos.CreationDate := Now;

    // Опції: стиснення + вбудовування шрифту (критично для кирилиці!)
    //Doc.Options := [poPageOriginAtTop, poCompressFonts, poCompressText,
    //                poNoEmbeddedFonts] - [poNoEmbeddedFonts];
    //// Простіше:
    //Doc.Options := [poPageOriginAtTop, poCompressFonts, poCompressText];
    Doc.Options := Doc.Options + [poNoEmbeddedFonts];

    Doc.StartDocument;

    // Секція + сторінка
    Section := Doc.Sections.AddSection;
    Page := Doc.Pages.AddPage;
    Page.PaperType := ptA4;
    Page.UnitOfMeasure := uomMillimeters;
    Section.AddPage(Page);

    //FontIdx := Doc.AddFont('C:\Windows\Fonts\arial.ttf', 'Arial');
    //FontIdx := Doc.AddFont('Helvetica');
    FontIdx := Doc.AddFont('C:\Windows\Fonts\LiberationSans-Regular.ttf', 'LiberationSans');
    Page.SetFont(FontIdx, 11);
    Page.SetColor(clBlack, False);

    // Пишемо текст рядок за рядком
    Y := 20; // верхній відступ у мм
    for i := 0 to AText.Count - 1 do
    begin
      Page.WriteText(20, Y, AText[i]);
      Inc(Y, 6); // крок між рядками
      if (Y > 280) then // нова сторінка якщо вийшли за A4
      begin
        Page := Doc.Pages.AddPage;
        Page.PaperType := ptA4;
        Page.UnitOfMeasure := uomMillimeters;
        Section.AddPage(Page);
        Page.SetFont(FontIdx, 11);
        Y := 20;
      end;
    end;

    Doc.SaveToFile(aFileName);
  finally
    Doc.Free();
  end;
end;

end.

