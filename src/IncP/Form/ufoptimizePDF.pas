// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFOptimizePDF;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uFBase, uGhostScript, uLog, uSettings, uSys, uVarUtil, uStateStore;

type

  { TFOptimizePDF }

  TFOptimizePDF = class(TFBase)
    ButtonConvert: TButton;
    ButtonDirIn: TButton;
    ButtonDirOut: TButton;
    CheckBoxCheckName: TCheckBox;
    LabeledEditDirIn: TLabeledEdit;
    LabeledEditDirOut: TLabeledEdit;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    procedure ButtonConvertClick(Sender: TObject);
    procedure ButtonDirInClick(Sender: TObject);
    procedure ButtonDirOutClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
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
  FileIn, FileOut, FileName, Ext: string;
  FilesIn: TStringList;
begin
  if (Trim(LabeledEditDirIn.Text) = '') then
  begin
    Log.Print('w', 'Не вказано паку вхідна');
    Exit;
  end;
  ForceDirectories(LabeledEditDirIn.Text);

  if (Trim(LabeledEditDirOut.Text) = '') then
  begin
    Log.Print('w', 'Не вказано паку вихідна');
    Exit;
  end;
  ForceDirectories(LabeledEditDirOut.Text);

  try
    FilesIn := GetDirFiles(LabeledEditDirIn.Text, '*.pdf;*.jpg');
    if (FilesIn.Count = 0) then
    begin
      Log.Print('w', 'Немає (PDF, JPG) файлів для оптимізації');
      Exit;
    end;

    Log.Print('i', 'Оптимізація файлів ...');
    FilesIn.Sort();
    for i := 0 to FilesIn.Count - 1 do
    begin
        FileIn := FilesIn[i];
        FileName := ChangeFileExt(ExtractFileName(FileIn), '');
        if (CheckBoxCheckName.Checked) then
        begin
          FileName := LatinToUkr(FileName);
          FileName := RemoveChars(FileName, '!@#$%^&_-+{}"|<>,');
        end;

        FileOut := LabeledEditDirOut.Text + PathDelim + FileName + '.pdf';
        Ext := LowerCase(ExtractFileExt(FileIn));
        if (Ext = '.pdf') then
          GS_OptimizePdf(FileIn, FileOut)
        else if (Ext = '.jpg') then
          GS_JpgToPdf(FileIn, FileOut)
        else
          continue;

        FileOutSize := FileGetSize(FileOut);
        Ratio := (1 - (FileOutSize / FileGetSize(FileIn))) * 100;
        Log.Print('i', Format('%d/%d %s %dkb (%.0f%%)', [i + 1, FilesIn.Count, FileIn, Round(FileOutSize/1000), Ratio]));
    end;
    Log.Print('i', 'Готово');
  finally
    FilesIn.Free();
  end;
end;

procedure TFOptimizePDF.SelectDir(aLabeledEdit: TLabeledEdit; const aKey: string);
begin
  if (DirectoryExists(aLabeledEdit.Text)) then
     SelectDirectoryDialog1.InitialDir := aLabeledEdit.Text;

  if (SelectDirectoryDialog1.Execute()) then
  begin
     Settings.SetItem(Name, aKey, SelectDirectoryDialog1.FileName);
     aLabeledEdit.Text := SelectDirectoryDialog1.FileName;
  end;
end;

procedure TFOptimizePDF.ButtonDirInClick(Sender: TObject);
begin
  SelectDir(LabeledEditDirIn, 'DirIn');
end;

procedure TFOptimizePDF.ButtonDirOutClick(Sender: TObject);
begin
  SelectDir(LabeledEditDirOut, 'DirOut');
end;

procedure TFOptimizePDF.FormCreate(Sender: TObject);
begin
  StateStore.Load(self);
end;

procedure TFOptimizePDF.FormDestroy(Sender: TObject);
begin
  StateStore.Save(self);
end;


end.

