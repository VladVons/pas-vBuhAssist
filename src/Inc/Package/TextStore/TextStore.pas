{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit TextStore;

{$warn 5023 off : no warning about unused units}
interface

uses
  uTextStore, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('uTextStore', @uTextStore.Register);
end;

initialization
  RegisterPackage('TextStore', @Register);
end.
