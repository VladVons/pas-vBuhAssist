unit uFTest;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ExtCtrls, fpjson, LConvEncoding,
  uFBase, uFWizard, uWizardUser, uWinManager, uSysVcl, uMacros, uHelper, uConst;

type
  { TFTest }
  TFTest = class(TFBase)
    BitBtnTestXml1: TBitBtn;
    BitBtnTestXml2: TBitBtn;
    BitBtnWizard0: TBitBtn;
    BitBtnWizardAll: TBitBtn;
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
  JObj, JObjMed: TJSONObject;
  JArr: TJSONArray;
begin
  if (not DirectoryExists(aDir)) then
    ForceDirectories(aDir);

  JObjMed := TJSONObject.Create();
  JObjMed.Add('_YEAR', YearOf(Date()));
  JObjMed.Add('_MONTH', MonthOf(Date()));
  JObjMed.Add('_DAY', DayOf(Date()));
  JObjMed.Add('_APP_NAME', cAppName);

  JArr := TJSONArray(ResourceLoadJson(aFile));
  JObj := JArr.Objects[0];

  Form := TFWizard(WinManager.Add(TFWizard));
  Form.SetHelper(TWizardUser.Create(Form));
  Form.Load(aDir, JObj, JObjMed);

  JArr.Free();
  JObjMed.Free();
end;

procedure TFTest.BitBtnWizard0Click(Sender: TObject);
begin
  Wizard('Data\D12345', 'FWizard');
end;

end.

