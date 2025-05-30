# GoogleAPIs

```pascal
Google := TGoogleAPI.Create;
GOOGLE_CLIENT_ID := '36897688****ntent.com';
GOOGLE_SECRET := 'GOC*****Vlgifa';
GOOGLE_AUTH_SCOPE := 'https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email';

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
