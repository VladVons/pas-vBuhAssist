unit uPDF;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fppdf;

procedure TextToPDF(const aFileName: string; const aText: TStringList);

implementation

procedure TextToPDF(const aFileName: string; const aText: TStringList);
const
  cPageHeight = 297;
  cMarginTop = 20;
  cMarginLeft = 10;
  cMarginBottom = 17;
  cLineStep = 6;
var
  Doc: TPDFDocument;
  Section: TPDFSection;
  Page: TPDFPage;
  FontIdx: Integer;
  i, Y: Integer;

  procedure NewPage();
  begin
    Page := Doc.Pages.AddPage();
    Page.PaperType := ptA4;
    Page.UnitOfMeasure := uomMillimeters;
    Section.AddPage(Page);
    Page.SetFont(FontIdx, 11);
    Page.SetColor(clBlack, False);
    Y := cMarginTop;
  end;

begin
  Doc := TPDFDocument.Create(nil);
  try
    Doc.Options := Doc.Options + [poNoEmbeddedFonts, poCompressFonts, poCompressText];
    Doc.StartDocument();

    Section := Doc.Sections.AddSection();
    FontIdx := Doc.AddFont('C:\Windows\Fonts\LiberationSans-Regular.ttf', 'LiberationSans');

    NewPage();
    for i := 0 to aText.Count - 1 do
    begin
      Page.WriteText(cMarginLeft, cPageHeight - Y, aText[i]);

      Inc(Y, cLineStep);
      if (Y > cPageHeight - cMarginBottom) then
        NewPage();
    end;

    Doc.SaveToFile(aFileName);
  finally
    Doc.Free();
  end;
end;

end.

