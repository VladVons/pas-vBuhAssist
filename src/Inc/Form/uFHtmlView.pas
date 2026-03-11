unit uFHtmlView;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs;

type
  { TFHtmlView }
  TFHtmlView = class(TForm)
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  FHtmlView: TFHtmlView;

implementation

{$R *.lfm}

{ TFHtmlView }

procedure TFHtmlView.FormCreate(Sender: TObject);
begin
  //HtmlViewer1.LoadFromString(UTF8Encode(PromoHTML));
end;

end.

