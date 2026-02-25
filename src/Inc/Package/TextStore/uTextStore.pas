unit uTextStore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TTextStore = class(TComponent)
  private
    fLines: TStringList;
    function GetLines(): TStrings;
    procedure SetLines(aValue: TStrings);
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy(); override;
  published
    property Lines: TStrings read GetLines write SetLines;
  end;

procedure Register();

implementation

procedure Register();
begin
  RegisterComponents('Samples', [TTextStore]);
end;

{ TTextStore }
constructor TTextStore.Create(aOwner: TComponent);
begin
  inherited Create(AOwner);
  fLines := TStringList.Create();
end;

destructor TTextStore.Destroy;
begin
  fLines.Free();
  inherited Destroy();
end;

function TTextStore.GetLines(): TStrings;
begin
  Result := fLines;
end;

procedure TTextStore.SetLines(aValue: TStrings);
begin
  FLines.Assign(AValue);
end;

end.
