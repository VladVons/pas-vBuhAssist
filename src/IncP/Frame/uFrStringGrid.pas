unit uFrStringGrid;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, ComCtrls, fpjson,
  uDmCommon,
  uExGrid, uLog, uGhostScript, uSys, uSysVcl;

type
  { TFrStringGrid }
   TFrStringGrid = class(TFrame)
    StringGridEx: TStringGridEx;
    OpenDialog: TOpenDialog;
    ToolBar1: TToolBar;
    ToolButtonAdd: TToolButton;
    ToolButtonDel: TToolButton;
    ToolButtonFile: TToolButton;
    procedure ToolButtonAddClick(Sender: TObject);
    procedure ToolButtonDelClick(Sender: TObject);
    procedure ToolButtonFileClick(Sender: TObject);
  private
    fFileCol: integer;
  public
    constructor Create(aOwner: TComponent); override;
    procedure LoadHeadFromJson(aJObj: TJSONObject);
    procedure LoadDataFromJson(aJArr: TJSONArray);
    function LoadDataToJson(): TJSONArray;
  end;

implementation
{$R *.lfm}

constructor TFrStringGrid.Create(aOwner: TComponent);
var
  SGEx: TStringGridEx;
begin
  inherited Create(aOwner);

  SGEx := StringGrid_Clone(StringGridEx, self);
  StringGridEx.Free();
  StringGridEx := SGEx;
end;

procedure TFrStringGrid.ToolButtonAddClick(Sender: TObject);
begin
  if (not StringGridEx.IsRowEmpty(StringGridEx.RowCount - 1)) then
    StringGridEx.RowCount := StringGridEx.RowCount + 1;
  StringGridEx.Row := StringGridEx.RowCount;
end;

procedure TFrStringGrid.ToolButtonDelClick(Sender: TObject);
begin
  StringGridEx.DelRow(StringGridEx.Row);
end;

procedure TFrStringGrid.ToolButtonFileClick(Sender: TObject);
const
  cDirData = 'Data';
var
  Ratio: double;
  FileOutSize: integer;
  Dir, Ext, FileIn, FileName, FileOut: string;
begin
  if (fFileCol = -1) or (StringGridEx.RowCount <= 1) then
    Exit();

  OpenDialog.Filter := 'Files (*.pdf;*.jpg;*.jpeg)|*.pdf;*.jpg;*.jpeg';
  //OpenDialog.Filter := 'Files (*.pdf;*.jpg;*.jpeg;*.bmp)|*.pdf;*.jpg;*.jpeg;*.bmp';
  if (not OpenDialog.Execute()) then
    Exit();

  FileIn := OpenDialog.FileName;
  FileName := ChangeFileExt(ExtractFileName(FileIn), '');
  FileName := LatinToUkr(FileName);
  FileName := RemoveChars(FileName, '!@#$%^&_-+{},');

  Dir := ConcatPaths([ExtractFilePath(ParamStr(0)), cDirData]);
  if (not DirectoryExists(Dir)) then
    ForceDirectories(Dir);

  Log.Print('i', Format('Конвертація %s ...', [FileName]));
  FileOut := ConcatPaths([Dir, FileName + '.pdf']);
  Ext := LowerCase(ExtractFileExt(FileIn));
  if (Ext = '.pdf') then
    GS_OptimizePdf(FileIn, FileOut)
  else if (Ext = '.jpg') then
    GS_JpgToPdf(FileIn, FileOut)
  else if (Ext = '.bmp') then
    GS_BmpToPdf(FileIn, FileOut);

  FileOutSize := FileGetSize(FileOut);
  Ratio := (1 - (FileOutSize / FileGetSize(FileIn))) * 100;
  Log.Print('i', Format('%s %dkb (%.0f%%)', [FileIn, Round(FileOutSize / 1000), Ratio]));

  StringGridEx.Cells[fFileCol, StringGridEx.Row] := FileOut;
end;

procedure TFrStringGrid.LoadHeadFromJson(aJObj: TJSONObject);
begin
  StringGridEx.HeadFromJson(aJObj);
  fFileCol := StringGridEx.FindCol('type', 'file');
  ToolButtonFile.Enabled := (fFileCol <> -1);
end;

procedure TFrStringGrid.LoadDataFromJson(aJArr: TJSONArray);
begin
  StringGridEx.DataFromJson(aJArr);
end;

function TFrStringGrid.LoadDataToJson(): TJSONArray;
begin
  Result := StringGridEx.DataToJson();
end;

end.

