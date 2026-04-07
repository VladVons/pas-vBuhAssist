unit uFrStringGrid;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Grids, ComCtrls, fpjson,
  uExGrid, uLog, uGhostScript, uSys, uSysVcl, uDbList;

type
  { TFrStringGrid }
   TFrStringGrid = class(TFrame)
    StringGridEx: TStringGridEx;
    ToolBar1: TToolBar;
    ToolButtonAdd: TToolButton;
    ToolButtonDel: TToolButton;
    procedure ToolButtonAddClick(Sender: TObject);
    procedure ToolButtonDelClick(Sender: TObject);
  private
    fParent: TForm;
    function DoOpenFileDialog(const aFile: string): string;
  public
    constructor Create(aOwner: TComponent); override;
    procedure LoadHeadFromJson(aJObj: TJSONObject; aParent: TForm);
    procedure Import(aJObj: TJSONObject);
    function Export(): TJSONObject;
  end;

implementation
{$R *.lfm}
uses
  uFWizard;

constructor TFrStringGrid.Create(aOwner: TComponent);
var
  SGEx: TStringGridEx;
begin
  inherited Create(aOwner);

  SGEx := StringGrid_Clone(StringGridEx, self);
  StringGridEx.Free();
  StringGridEx := SGEx;
  StringGridEx.OnOpenFileDialog := @DoOpenFileDialog;
end;

procedure TFrStringGrid.ToolButtonAddClick(Sender: TObject);
var
  MaxRows: integer;
begin
  MaxRows := StringGridEx.GetMaxRows();
  if (MaxRows = -1) or (MaxRows < StringGridEx.RowCount) then
    Exit();

  if (not StringGridEx.IsRowEmpty(StringGridEx.RowCount - 1)) then
    StringGridEx.RowCount := StringGridEx.RowCount + 1;
  StringGridEx.Row := StringGridEx.RowCount;
end;

procedure TFrStringGrid.ToolButtonDelClick(Sender: TObject);
begin
  StringGridEx.DelRow(StringGridEx.Row);
end;

function TFrStringGrid.DoOpenFileDialog(const aFile: string): string;
var
  Ratio: double;
  FileOutSize: integer;
  Dir, DirApp, Ext, FileName, FileOut: string;
  begin
  FileName := ChangeFileExt(ExtractFileName(aFile), '');
  FileName := LatinToUkr(FileName);
  FileName := RemoveChars(FileName, '!@#$%^&_-+{},');

  DirApp := GetAppDir();
  Dir := ConcatPaths([DirApp, TFWizard(fParent).GetDir()]);
  if (not DirectoryExists(Dir)) then
    ForceDirectories(Dir);

  Working(True);
  Log.Print('i', Format('Конвертація %s ...', [FileName]));
  FileOut := ConcatPaths([Dir, FileName + '.pdf']);
  Ext := LowerCase(ExtractFileExt(aFile));
  if (Ext = '.pdf') then
    GS_OptimizePdf(aFile, FileOut)
  else if (Ext = '.jpg') then
    GS_JpgToPdf(aFile, FileOut)
  else if (Ext = '.bmp') then
    GS_BmpToPdf(aFile, FileOut);

  FileOutSize := FileGetSize(FileOut);
  Ratio := (1 - (FileOutSize / FileGetSize(aFile))) * 100;
  Log.Print('i', Format('%s %dkb (%.0f%%)', [aFile, Round(FileOutSize / 1000), Ratio]));
  Working(False);

  Result := FileOut.Replace(DirApp, '');
end;

procedure TFrStringGrid.LoadHeadFromJson(aJObj: TJSONObject; aParent: TForm);
begin
  fParent := aParent;
  StringGridEx.LoadHeadFromJson(aJObj);
end;

procedure TFrStringGrid.Import(aJObj: TJSONObject);
begin
  StringGridEx.Import(aJObj);
end;

function TFrStringGrid.Export(): TJSONObject;
begin
  Result := StringGridEx.Export();
end;

end.


