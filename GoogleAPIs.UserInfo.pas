unit GoogleAPIs.UserInfo;

interface

uses
  System.Classes, Rest.Json, Rest.Json.Types, HGM.FastClientAPI;

type
  TUserInfo = class
  private
    [JsonNameAttribute('sub')]
    FSub: string;
    [JsonNameAttribute('name')]
    FName: string;
    [JsonNameAttribute('given_name')]
    FGivenName: string;
    [JsonNameAttribute('picture')]
    FPicture: string;
    [JsonNameAttribute('email')]
    FEmail: string;
    [JsonNameAttribute('email_verified')]
    FEmailVerified: Boolean;
  public
    property Sub: string read FSub write FSub;
    property Name: string read FName write FName;
    property GivenName: string read FGivenName write FGivenName;
    property Picture: string read FPicture write FPicture;
    property Email: string read FEmail write FEmail;
    property EmailVerified: Boolean read FEmailVerified write FEmailVerified;
  end;

  TUserInfoRoute = class(TAPIRoute)
    function GetCurrent: TUserInfo;
  end;

implementation

{ TUserInfoRoute }

function TUserInfoRoute.GetCurrent: TUserInfo;
begin
  Result := API.Get<TUserInfo>('oauth2/v3/userinfo');
end;

end.

