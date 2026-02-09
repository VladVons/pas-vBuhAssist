unit uFOptimizePDF;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uGhostScript, uSettings, uForms, uSys;

type

  { TFOptimizePDF }

  TFOptimizePDF = class(TForm)
    ButtonConvert: TButton;
    ButtonDirIn: TButton;
    ButtonDirOut: TButton;
    LabeledEditDirIn: TLabeledEdit;
    LabeledEditDirOut: TLabeledEdit;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    procedure ButtonConvertClick(Sender: TObject);
    procedure ButtonDirInClick(Sender: TObject);
    procedure ButtonDirOutClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure SelectDir(aLabeledEdit: TLabeledEdit; const aKey: string);
  public

  end;

var
  FOptimizePDF: TFOptimizePDF;

implementation

{$R *.lfm}

{ TFOptimizePDF }

procedure TFOptimizePDF.ButtonConvertClick(Sender: TObject);
var
  Ratio: double;
  i, FileOutSize: integer;
  FileIn, FileOut: string;
  FilesIn: TStringList;
begin
  if (Trim(LabeledEditDirIn.Text) = '') then
  begin
    Log('Не вказано паку вхідна');
    Exit;
  end;

  if (Trim(LabeledEditDirOut.Text) = '') then
  begin
    Log('Не вказано паку вихідна');
    Exit;
  end;

  try
    FilesIn := GetDirFiles(LabeledEditDirIn.Text, '*.pdf');
    if (FilesIn.Count = 0) then
    begin
      Log('Немає PDF файлів для оптимізації');
      Exit;
    end;

    Log('Оптимізація файлів ...');
    FilesIn.Sort();
    for i := 0 to FilesIn.Count - 1 do
    begin
        FileIn := FilesIn[i];
        FileOut := LabeledEditDirOut.Text + PathDelim + ExtractFileName(FileIn);
        ExecOptimizePDF(FileIn, FileOut);
        FileOutSize := GetFileSize(FileOut);
        Ratio := (1 - (FileOutSize / GetFileSize(FileIn))) * 100;
        Log(Format('%d/%d %s %dkb (%.0f%%)', [i + 1, FilesIn.Count, FileIn, Round(FileOutSize/1000), Ratio]));
    end;

  finally
    FilesIn.Free();
  end;
end;

procedure TFOptimizePDF.SelectDir(aLabeledEdit: TLabeledEdit; const aKey: string);
begin
  if DirectoryExists(aLabeledEdit.Text) then
     SelectDirectoryDialog1.InitialDir := aLabeledEdit.Text;

  if SelectDirectoryDialog1.Execute() then
     ConfWriteKey('OptimizePDF', aKey, SelectDirectoryDialog1.FileName);
     aLabeledEdit.Text := SelectDirectoryDialog1.FileName;
end;

procedure TFOptimizePDF.ButtonDirInClick(Sender: TObject);
begin
  SelectDir(LabeledEditDirIn, 'DirIn');
end;

procedure TFOptimizePDF.ButtonDirOutClick(Sender: TObject);
begin
  SelectDir(LabeledEditDirOut, 'DirOut');
end;

procedure TFOptimizePDF.FormShow(Sender: TObject);
begin
  LabeledEditDirIn.Text := ConfReadKey('OptimizePDF', 'DirIn');
  LabeledEditDirOut.Text := ConfReadKey('OptimizePDF', 'DirOut');
end;

end.

