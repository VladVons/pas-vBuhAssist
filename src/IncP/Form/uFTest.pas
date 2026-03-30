unit uFTest;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ExtCtrls, fpjson, uFBase, uFWizard, uWinManager, uSysVcl, uHelper;

type

  { TFTest }
  TFTest = class(TFBase)
    BitBtnTestXml: TBitBtn;
    BitBtnWizard0: TBitBtn;
    BitBtnWizardAll: TBitBtn;
    Memo1: TMemo;
    Memo2: TMemo;
    Panel1: TPanel;
    procedure BitBtnTestXmlClick(Sender: TObject);
    procedure BitBtnWizard0Click(Sender: TObject);
    procedure BitBtnWizardAllClick(Sender: TObject);
  private
    procedure Wizard(const aDir, aFile: string);
  public
  end;


implementation

{$R *.lfm}
{ TFTest }

procedure TFTest.Wizard(const aDir, aFile: string);
var
  Path: string;
  Form: TFWizard;
begin
  if (not DirectoryExists(aDir)) then
    ForceDirectories(aDir);

  Form := TFWizard(WinManager.Add(TFWizard));
  Form.LoadScheme(aFile);

  Path := ConcatPaths([aDir, aFile + '_dat.json']);
  Form.LoadData(Path);
end;

procedure TFTest.BitBtnWizard0Click(Sender: TObject);
begin
  Wizard('Data\12345', 'FWizardPdv0');
end;

procedure TFTest.BitBtnTestXmlClick(Sender: TObject);
const
  cName = 'J1360102';
var
  Str, StrXds, Path: string;
begin
  StrXds := ResourceLoadString(cName, 'xml');
  Str := StrXds.Macros(Memo1.Lines).DelEmptyLines();
  Memo2.Text := Str;
  //TStringList(Memo2.Lines).DelEmpty();
  Path := ConcatPaths(['Data', cName + '.xml']);
  Str.ToFile(Path);
  Log('i', Path);
end;

procedure TFTest.BitBtnWizardAllClick(Sender: TObject);
var
  Form: TFWizard;
begin
  Form := TFWizard(WinManager.Add(TFWizard));
  Form.Load('FWizardPdvs');
end;

end.

