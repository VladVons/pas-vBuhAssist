unit uArchive;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Zipper;

procedure UnZipToDir(const aFileIn, aDirOut: string);

implementation

procedure UnZipToDir(const aFileIn, aDirOut: string);
var
  UnZipper: TUnZipper;
begin
  if (not DirectoryExists(aDirOut)) then
    ForceDirectories(aDirOut);

  UnZipper := TUnZipper.Create;
  try
    UnZipper.FileName := aFileIn;
    UnZipper.OutputPath := aDirOut;
    UnZipper.Examine();
    UnZipper.UnZipAllFiles();
  finally
    UnZipper.Free();
  end;
end;

end.

