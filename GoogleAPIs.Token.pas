unit GoogleAPIs.Token;

interface

uses
  System.Classes, Rest.Json, Rest.Json.Types, HGM.FastClientAPI, System.Net.Mime;

type
  TTokenParams = class(TFastMultipartFormData);

  TTokenResponse = class
  private
    [JsonNameAttribute('access_token')]
    FAccessToken: string;
    [JsonNameAttribute('expires_in')]
    FExpiresIn: UInt64;
    [JsonNameAttribute('scope')]
    FScope: string;
    [JsonNameAttribute('token_type')]
    FTokenType: string;
    [JsonNameAttribute('id_token')]
    FIdToken: string;
    [JsonNameAttribute('refresh_token')]
    FRefreshToken: string;
  public
    property AccessToken: string read FAccessToken write FAccessToken;
    property ExpiresIn: UInt64 read FExpiresIn write FExpiresIn;
    property Scope: string read FScope write FScope;
    property TokenType: string read FTokenType write FTokenType;
    property IdToken: string read FIdToken write FIdToken;
    property RefreshToken: string read FRefreshToken write FRefreshToken;
  end;

  TTokenRoute = class(TAPIRoute)
    function GetToken(const Code, ClientId, ClientSecret, RedirectUri: string): TTokenResponse;
  end;

implementation


{ TTokenRoute }

function TTokenRoute.GetToken(const Code, ClientId, ClientSecret, RedirectUri: string): TTokenResponse;
begin
  Result := API.PostForm<TTokenResponse, TTokenParams>('https://oauth2.googleapis.com/token',
    procedure(Params: TTokenParams)
    begin
      Params.AddField('code', Code);
      Params.AddField('client_id', ClientId);
      Params.AddField('client_secret', ClientSecret);
      Params.AddField('redirect_uri', RedirectUri);
      Params.AddField('grant_type', 'authorization_code');
    end);
end;

end.

