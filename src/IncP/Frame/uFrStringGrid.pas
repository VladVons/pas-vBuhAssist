unit uFrStringGrid;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Grids, ComCtrls,
  fpjson, uExGrid, uLog, uGhostScript, uSys, uSysVcl;

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
    function DoOpenFileDialog(const aFile: string): string;
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
  StringGridEx.OnOpenFileDialog := @DoOpenFileDialog;
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

function TFrStringGrid.DoOpenFileDialog(const aFile: string): string;
const
  cDirData = 'Data';
var
  Ratio: double;
  FileOutSize: integer;
  Dir, Ext, FileName, FileOut: string;
begin
  FileName := ChangeFileExt(ExtractFileName(aFile), '');
  FileName := LatinToUkr(FileName);
  FileName := RemoveChars(FileName, '!@#$%^&_-+{},');

  Dir := ConcatPaths([ExtractFilePath(ParamStr(0)), cDirData]);
  if (not DirectoryExists(Dir)) then
    ForceDirectories(Dir);

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

  Result := aFile;
end;

procedure TFrStringGrid.LoadHeadFromJson(aJObj: TJSONObject);
begin
  StringGridEx.HeadFromJson(aJObj);
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

