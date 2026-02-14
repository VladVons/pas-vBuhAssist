// Created: 2026.02.05
// Author: Vladimir Vons <VladVons@gmail.com>

unit uFOptimizePDF;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uGhostScript, uLog, uSettings, uSys, uVarUtil;

type

  { TFOptimizePDF }

  TFOptimizePDF = class(TForm)
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
    procedure FormHide(Sender: TObject);
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
  FileIn, FileOut, LatFilter, FileName, Ext: string;
  FilesIn: TStringList;
begin
  if (Trim(LabeledEditDirIn.Text) = '') then
  begin
    Log.Print('Не вказано паку вхідна');
    Exit;
  end;

  if (Trim(LabeledEditDirOut.Text) = '') then
  begin
    Log.Print('Не вказано паку вихідна');
    Exit;
  end;

  try
    FilesIn := GetDirFiles(LabeledEditDirIn.Text, '*.pdf;*.jpg');
    if (FilesIn.Count = 0) then
    begin
      Log.Print('Немає (PDF, JPG) файлів для оптимізації');
      Exit;
    end;

    Log.Print('Оптимізація файлів ...');
    FilesIn.Sort();
    for i := 0 to FilesIn.Count - 1 do
    begin
        FileIn := FilesIn[i];
        FileName := ChangeFileExt(ExtractFileName(FileIn), '');
        if (CheckBoxCheckName.Checked) then
        begin
          LatFilter := ExtractLatin(FileName);
          if (Length(LatFilter) > 0) Then
             Log.Print('В назві файла є латинські букви: ' + LatFilter);
        end;

        Ext := LowerCase(ExtractFileExt(FileIn));
        if (Ext = '.pdf') then
        begin
          FileOut := LabeledEditDirOut.Text + PathDelim + ExtractFileName(FileIn);
          GS_OptimizePdf(FileIn, FileOut);
        end else begin
          FileOut := LabeledEditDirOut.Text + PathDelim + ChangeFileExt(ExtractFileName(FileIn), '.pdf');
          GS_JpgToPdf(FileIn, FileOut);
          end;

        FileOutSize := FileGetSize(FileOut);
        Ratio := (1 - (FileOutSize / FileGetSize(FileIn))) * 100;
        Log.Print(Format('%d/%d %s %dkb (%.0f%%)', [i + 1, FilesIn.Count, FileIn, Round(FileOutSize/1000), Ratio]));
    end;
    Log.Print('Готово');
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
     ConfKeyWrite('OptimizePDF', aKey, SelectDirectoryDialog1.FileName);
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

procedure TFOptimizePDF.FormHide(Sender: TObject);
begin

end;

procedure TFOptimizePDF.FormShow(Sender: TObject);
begin
  LabeledEditDirIn.Text := ConfKeyRead('OptimizePDF', 'DirIn');
  LabeledEditDirOut.Text := ConfKeyRead('OptimizePDF', 'DirOut');
  CheckBoxCheckName.Checked := ConfKeyRead('OptimizePDF', 'CheckBoxCheckName') = 'true';
  LabeledEditDirOut.Text := ConfKeyRead('OptimizePDF', 'DirOut');
end;

end.

