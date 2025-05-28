unit GoogleAPIs.Drive.FileList;

interface

uses
  Rest.Json, Rest.Json.Types;

type
  TDriveFiles = class
  private
    [JsonNameAttribute('kind')]
    FKind: string;
    [JsonNameAttribute('id')]
    FId: string;
    [JsonNameAttribute('name')]
    FName: string;
    [JsonNameAttribute('mimeType')]
    FMimeType: string;
  public
    property Kind: string read FKind write FKind;
    property Id: string read FId write FId;
    property Name: string read FName write FName;
    property MimeType: string read FMimeType write FMimeType;
  end;

  TFileList = class
  private
    [JsonNameAttribute('files')]
    FFiles: TArray<TDriveFiles>;
    [JsonNameAttribute('kind')]
    FKind: string;
    [JsonNameAttribute('nextPageToken')]
    FNextPageToken: string;
    [JsonNameAttribute('incompleteSearch')]
    FIncompleteSearch: Boolean;
  public
    property Files: TArray<TDriveFiles> read FFiles write FFiles;
    property Kind: string read FKind write FKind;
    property NextPageToken: string read FNextPageToken write FNextPageToken;
    property IncompleteSearch: Boolean read FIncompleteSearch write FIncompleteSearch;
    destructor Destroy; override;
  end;

implementation

{ TFileList }

destructor TFileList.Destroy;
begin
  for var Item in FFiles do
    Item.Free;
  inherited;
end;

end.

