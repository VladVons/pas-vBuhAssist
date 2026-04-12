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
    Image1: TImage;
    Panel1: TPanel;
    procedure BitBtnWizard0Click(Sender: TObject);
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
  Form.SetHelper(TWizardUser.Create(Form));
  Form.LoadFormScheme(aFile);

  Path := ConcatPaths([aDir, aFile + '.json']);
  Form.LoadFormData(Path);
  Form.GetDataInt();
end;

procedure TFTest.BitBtnWizard0Click(Sender: TObject);
var
  JObj: TJSONObject;
begin
  Wizard(cDirData, 'g00w10');
end;

end.

