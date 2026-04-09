unit uFTest;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ExtCtrls, fpjson, LConvEncoding,
  uFBase, uFWizard, uWizardUser, uWinManager, uSysVcl, uMacros, uHelper;

const
  cDirData = 'Data\D12345';

type
  { TFTest }
  TFTest = class(TFBase)
    BitBtnTestXml1: TBitBtn;
    BitBtnTestXml2: TBitBtn;
    BitBtnWizard0: TBitBtn;
    BitBtnWizardAll: TBitBtn;
    Memo1: TMemo;
    Memo2: TMemo;
    Panel1: TPanel;
    procedure BitBtnTestXml1Click(Sender: TObject);
    procedure BitBtnTestXml2Click(Sender: TObject);
    procedure BitBtnWizard0Click(Sender: TObject);
    procedure BitBtnWizardAllClick(Sender: TObject);
  private
    procedure Wizard(const aDir, aFile: string);
    procedure TestXml(const aName: string);
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
  Form.SetHelper(TWizardUser.Create(Form));
  Form.LoadFormScheme(aFile);

  Path := ConcatPaths([aDir, aFile + '.json']);
  Form.LoadFormData(Path);
  Form.GetDataInt();
end;

procedure TFTest.BitBtnWizard0Click(Sender: TObject);
begin
  //Wizard(cDirData, 'FWizardPdv1');
end;

procedure TFTest.TestXml(const aName: string);
var
  Str, StrXds, Path: string;
  Macros: TMacros;
begin
  StrXds := ResourceLoadString(aName, 'xml');
  Macros := TMacros.Create();
  Macros.Load(StrXds);
  Str := Macros.Parse(TStringList(Memo1.Lines)).DelEmptyLines();
  Memo2.Text := Str;
  Macros.Free();

  //TStringList(Memo2.Lines).DelEmpty();
  Path := ConcatPaths(['Data', aName + '.xml']);
  Str := UTF8ToCP1251(Str);
  Str.ToFile(Path);
  Log('i', Path);
end;

procedure TFTest.BitBtnTestXml1Click(Sender: TObject);
begin
  TestXml('J1360102');
end;

procedure TFTest.BitBtnTestXml2Click(Sender: TObject);
begin
  TestXml('J1312603');
end;

procedure TFTest.BitBtnWizardAllClick(Sender: TObject);
var
  Form: TFWizard;
begin
  Form := TFWizard(WinManager.Add(TFWizard));
  Form.Load('FWizardPdvs', cDirData, nil);
end;

end.

