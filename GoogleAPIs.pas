unit GoogleAPIs;

interface

uses
  System.SysUtils, HGM.FastClientAPI, GoogleAPIs.UserInfo, GoogleAPIs.Drive;

type
  TGoogleAPI = class(TCustomAPI)
  public
    const
      BASE_API_URL = 'https://www.googleapis.com';
  private
    FDrive: TGoogleDriveRoute;
    FUserInfo: TUserInfoRoute;
    function GetDrive: TGoogleDriveRoute;
    function GetUserInfo: TUserInfoRoute;
  public
    property Drive: TGoogleDriveRoute read GetDrive;
    property UserInfo: TUserInfoRoute read GetUserInfo;
  public
    procedure Auth(Callback: TProc<Boolean, string>);
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

uses
  GoogleAPIs.Auth;

{ TGoogleAPI }

procedure TGoogleAPI.Auth(Callback: TProc<Boolean, string>);
begin
  try
    ProcTokenCallback :=
      procedure(AToken: string)
      begin
        Token := AToken;
        Callback(not Token.IsEmpty, '');
      end;
    RunServer;
    StartGetTokenProcess;
  except
    on E: Exception do
      Callback(False, E.Message);
  end;
end;

constructor TGoogleAPI.Create;
begin
  inherited;
  BaseUrl := BASE_API_URL;
end;

destructor TGoogleAPI.Destroy;
begin
  ProcTokenCallback := nil;
  StopServer;
  FDrive.Free;
  FUserInfo.Free;
  inherited;
end;

function TGoogleAPI.GetDrive: TGoogleDriveRoute;
begin
  if not Assigned(FDrive) then
    FDrive := TGoogleDriveRoute.CreateRoute(Self);
  Result := FDrive;
end;

function TGoogleAPI.GetUserInfo: TUserInfoRoute;
begin
  if not Assigned(FUserInfo) then
    FUserInfo := TUserInfoRoute.CreateRoute(Self);
  Result := FUserInfo;
end;

end.

