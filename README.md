# GoogleAPIs

```pascal
uses GoogleAPIs, GoogleAPIs.Auth;

var Google := TGoogleAPI.Create;
```

Auth
```pascal
Google.ClientId := '36897688****ntent.com';
Google.ClientSecret := 'GOC*****Vlgifa';
Google.Scope := 'https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email';

// async work
Google.Auth(
  procedure(Success: Boolean; Error: string)
  begin
    if Success then
    begin
      var UserInfo := Google.UserInfo.GetCurrent;
      if Assigned(UserInfo) then
      try
        UserName := UserInfo.Name;
        UserPicture := UserInfo.Picture;
      finally
        UserInfo.Free;
      end;
    end
    else
      ShowMessage(Error);
  end);
```

or

```pascal
Google.Token := 'your_token';
```
