{********************************************************}
{ JBS Laz Version Info Library                           }
{                                                        }
{ Copyright (c) 2013 JBS Soluções.                       }
{                                                        }
{********************************************************}

Unit versioninfo;

{$mode objfpc}

Interface

Uses
  Classes, SysUtils;

Function GetAboutInfo: String;
Function GetFileVersion: String;
Function GetProductVersion: String;
Function GetCompanyName: String;
Function GetFileDescription: String;
Function GetCopyright: String;
Function GetCompiledDate: String;
Function GetCompilerInfo: String;
Function GetTargetInfo: String;
Function GetOS: String;
Function GetResourceInfo(InfoValue: string): String;
Function GetResourceStrings(oStringList : TStringList) : Boolean;
Function GetLCLVersion: String;
function GetWidgetSet: string;

Const
  WIDGETSET_GTK        = 'GTK widget set';
  WIDGETSET_GTK2       = 'GTK 2 widget set';
  WIDGETSET_WIN        = 'Win32/Win64 widget set';
  WIDGETSET_WINCE      = 'WinCE widget set';
  WIDGETSET_CARBON     = 'Carbon widget set';
  WIDGETSET_QT         = 'QT widget set';
  WIDGETSET_fpGUI      = 'fpGUI widget set';
  WIDGETSET_OTHER      = 'Other gui';

Implementation

Uses
  resource, versiontypes, versionresource, LCLVersion, InterfaceBase;

Type
  TVersionInfo = Class
  private
    FBuildInfoAvailable: Boolean;
    FVersResource: TVersionResource;
    Function GetFixedInfo: TVersionFixedInfo;
    Function GetStringFileInfo: TVersionStringFileInfo;
    Function GetVarFileInfo: TVersionVarFileInfo;
  public
    Constructor Create;
    Destructor Destroy; override;

    Procedure Load(Instance: THandle);

    Property BuildInfoAvailable: Boolean Read FBuildInfoAvailable;

    Property FixedInfo: TVersionFixedInfo Read GetFixedInfo;
    Property StringFileInfo: TVersionStringFileInfo Read GetStringFileInfo;
    Property VarFileInfo: TVersionVarFileInfo Read GetVarFileInfo;
  End;

function GetWidgetSet: string;
begin
  case WidgetSet.LCLPlatform of
    lpGtk:   Result := WIDGETSET_GTK;
    lpGtk2:  Result := WIDGETSET_GTK2;
    lpWin32: Result := WIDGETSET_WIN;
    lpWinCE: Result := WIDGETSET_WINCE;
    lpCarbon:Result := WIDGETSET_CARBON;
    lpQT:    Result := WIDGETSET_QT;
    lpfpGUI: Result := WIDGETSET_fpGUI;
  else
    Result:=WIDGETSET_OTHER;
  end;
end;

Function GetCompilerInfo: String;
begin
  Result := 'FPC '+{$I %FPCVERSION%};
end;

Function GetTargetInfo: String;
begin
  Result := {$I %FPCTARGETCPU%}+' - '+{$I %FPCTARGETOS%};
end;

Function GetOS: String;
Begin
  Result := {$I %FPCTARGETOS%};
End;

Function GetLCLVersion: String;
begin
  Result := 'LCL '+lcl_version;
end;

Function GetCompiledDate: String;
Var
  sDate, sTime: String;
Begin
  sDate := {$I %DATE%};
  sTime := {$I %TIME%};

  Result := sDate + ' at ' + sTime;
End;

{ Routines to expose TVersionInfo data }

Var
  FInfo: TVersionInfo;

Procedure CreateInfo;
Begin
  If Not Assigned(FInfo) Then
  Begin
    FInfo := TVersionInfo.Create;
    FInfo.Load(HINSTANCE);
  End;
End;

Function GetResourceStrings(oStringList: TStringList): Boolean;
Var
  i, j : Integer;
  oTable : TVersionStringTable;
begin
  CreateInfo;

  oStringList.Clear;
  Result := False;

  If FInfo.BuildInfoAvailable Then
  Begin
    Result := True;
    For i := 0 To FInfo.StringFileInfo.Count-1 Do
    Begin
      oTable := FInfo.StringFileInfo.Items[i];

      For j := 0 To oTable.Count-1 Do
        If Trim(oTable.ValuesByIndex[j])<>'' Then
          oStringList.Values[oTable.Keys[j]] := oTable.ValuesByIndex[j];
    end;
  end;
end;

Function ProductVersionToString(PV: TFileProductVersion): String;
Begin
  Result := Format('%d.%d.%d.%d', [PV[0], PV[1], PV[2], PV[3]]);
End;

Function GetProductVersion: String;
Begin
  CreateInfo;

  If FInfo.BuildInfoAvailable Then
    Result := ProductVersionToString(FInfo.FixedInfo.ProductVersion)
  Else
    Result := 'N/A';
End;

function GetAboutInfo: String;
var
  sRes: string;
begin
  sRes := 'Description: '+ GetFileDescription + #13#10;
  sRes := sRes + 'File Version: '+ GetFileVersion + #13#10;
  sRes := sRes + 'Date: '+ GetCompiledDate + #13#10;
  sRes := sRes + 'Copyright: '+ GetCopyright + #13#10;
  sRes := sRes + 'Company Name: '+ GetCompanyName;

  Result := sRes;
end;

Function GetFileVersion: String;
Begin
  CreateInfo;

  If FInfo.BuildInfoAvailable Then
    Result := ProductVersionToString(FInfo.FixedInfo.FileVersion)
  Else
    Result := 'Not available';
End;

{ TVersionInfo }

Function TVersionInfo.GetFixedInfo: TVersionFixedInfo;
Begin
  Result := FVersResource.FixedInfo;
End;

Function TVersionInfo.GetStringFileInfo: TVersionStringFileInfo;
Begin
  Result := FVersResource.StringFileInfo;
End;

Function TVersionInfo.GetVarFileInfo: TVersionVarFileInfo;
Begin
  Result := FVersResource.VarFileInfo;
End;

Constructor TVersionInfo.Create;
Begin
  Inherited Create;

  FVersResource := TVersionResource.Create;
  FBuildInfoAvailable := False;
End;

Destructor TVersionInfo.Destroy;
Begin
  FVersResource.Free;

  Inherited Destroy;
End;

Procedure TVersionInfo.Load(Instance: THandle);
Var
  Stream: TResourceStream;
  ResID: Integer;
  Res: TFPResourceHandle;
Begin
  FBuildInfoAvailable := False;
  ResID := 1;

  // Defensive code to prevent failure if no resource available...
  Res := FindResource(Instance, PChar(PtrInt(ResID)), PChar(RT_VERSION));
  If Res = 0 Then
    Exit;

  {$IFDEF WINCE}
  Stream := TResourceStream.CreateFromID(Instance, ResID, PWideChar(RT_VERSION));
  {$ELSE}
  Stream := TResourceStream.CreateFromID(Instance, ResID, PChar(RT_VERSION));
  {$ENDIF}

  Try
    FVersResource.SetCustomRawDataStream(Stream);

    // access some property to load from the stream
    FVersResource.FixedInfo;

    // clear the stream
    FVersResource.SetCustomRawDataStream(nil);

    FBuildInfoAvailable := True;
  Finally
    Stream.Free;
  End;
End;

Function GetResourceInfo(InfoValue: string): String;
var
  slInfo: TStringList;
begin
  try
    try
      slInfo := TStringList.Create;

      if GetResourceStrings(slInfo) then
        result := slInfo.values[InfoValue]
      else
        result := 'N/A';
    except
      result := 'N/A';
    end;
  finally
    slInfo.free;
    slInfo := nil;
  end;
end;

Function GetCompanyName: string;
begin
  result := GetResourceInfo('CompanyName');
end;

Function GetFileDescription: String;
begin
  result := GetResourceInfo('FileDescription');
end;

Function GetCopyright: String;
begin
  result := GetResourceInfo('LegalCopyright');
end;

Initialization
  FInfo := nil;

Finalization
  If Assigned(FInfo) Then
    FInfo.Free;
End.
