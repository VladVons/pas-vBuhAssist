unit uWizardUser;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, LConvEncoding,
  uFWizard, uVarUtil, uSysVcl, uHelper, uLog;

type
  TWizardUser = class(TPersistent)
  published
    procedure OnClick_FWizardPdv5_Save(Sender: TObject);
  private
    fParent: TFWizard;
    procedure SaveXml(const aName: string; aJObj: TJSONObject; aIdx: integer);
  public
    constructor Create(aParent: TFWizard);
  end;

implementation

constructor TWizardUser.Create(aParent: TFWizard);
begin
  inherited Create();
  fParent := aParent;
end;

procedure TWizardUser.SaveXml(const aName: string; aJObj: TJSONObject; aIdx: integer);
var
  StrXds, Path, FileName, No, FJ: string;
  Macros: TMacros;
  SL: TStringList;
begin
  FJ := IIF(Length(aJObj.Get('TIN', '')) = 8, 'J', 'F');
  No := '1000000009';
  FileName := Format('%s_00_%s_%s_%d%.2d%d_%s%s_%s', [
    aJObj.Get('HKSTI', ''),
    aJObj.Get('TIN', ''),
    No,
    aJObj.Get('DAY', 0),
    aJObj.Get('MONTH', 0),
    aJObj.Get('YEAR', 0),
    FJ,
    aName,
    aJObj.Get('HKSTI', '')
  ]);
  FileName := FileName.Replace('_', '') + '.XML';
  aJObj.Add(Format('FILENAME_%d', [aIdx]), FileName);

  Macros := TMacros.Create();
  try
    StrXds := ResourceLoadString(aName, 'xml');
    StrXds := Macros.Exec(StrXds, aJObj).DelEmptyLines();
    StrXds := UTF8ToCP1251(StrXds);

    SL := Macros.GetList(StrXds);
    if (SL.Count > 0) then
      Log.Print('i', Format('Не заповнено макроси %d: %s', [SL.Count, SL.CommaText]));
    SL.Free();
  finally
    Macros.Free();
  end;

  Path := ConcatPaths(['Data', FileName]);
  StrXds.ToFile(Path);
  Log.Print('i', Path);
end;

procedure TWizardUser.OnClick_FWizardPdv5_Save(Sender: TObject);
var
  JObjDb: TJSONObject;
begin
  JObjDb := fParent.GetDataExt();
  SaveXml('1360102', JObjDb, 1);
  SaveXml('1312603', JObjDb, 2);
end;


end.

