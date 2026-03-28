unit uFTest;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons,
  uFBase, uFWizard,
  uWinManager, uHelper;

type

  { TFTest }
  TFTest = class(TFBase)
    BitBtnWizard1: TBitBtn;
    BitBtnWizard2: TBitBtn;
    BitBtnWizard3: TBitBtn;
    BitBtnWizard4: TBitBtn;
    BitBtnWizard5: TBitBtn;
    BitBtnWizard0: TBitBtn;
    procedure BitBtnWizard0Click(Sender: TObject);
    procedure BitBtnWizard1Click(Sender: TObject);
    procedure BitBtnWizard2Click(Sender: TObject);
    procedure BitBtnWizard3Click(Sender: TObject);
    procedure BitBtnWizard4Click(Sender: TObject);
    procedure BitBtnWizard5Click(Sender: TObject);
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

procedure TFTest.BitBtnWizard1Click(Sender: TObject);
begin
  Wizard('Data\12345', 'FWizardPdv1');
end;

procedure TFTest.BitBtnWizard2Click(Sender: TObject);
begin
  Wizard('Data\12345', 'FWizardPdv2');
end;

procedure TFTest.BitBtnWizard3Click(Sender: TObject);
begin
  Wizard('Data\12345', 'FWizardPdv3');
end;

procedure TFTest.BitBtnWizard4Click(Sender: TObject);
begin
  Wizard('Data\12345', 'FWizardPdv4');
end;

procedure TFTest.BitBtnWizard5Click(Sender: TObject);
begin
  Wizard('Data\12345', 'FWizardPdv5');
end;

end.

