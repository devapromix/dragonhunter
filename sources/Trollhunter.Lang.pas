unit Trollhunter.Lang;

interface

uses
  System.Classes,
  Dragonhunter.Item,
  Trollhunter.Creature,
  Dragonhunter.Map;

type
  TLanguageString = class(TObject)
  private
    FId: TStringList;
    FEn: TStringList;
    FRu: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(const AId, AEn, ARu: string);
    property ID: TStringList read FId write FId;
    property En: TStringList read FEn write FEn;
    property Ru: TStringList read FRu write FRu;
  end;

type
  TLanguage = class(TObject)
  private
    FCurrentLanguageIndex: Byte;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromResources;
    property CurrentLanguageIndex: Byte read FCurrentLanguageIndex
      write FCurrentLanguageIndex;
    function GetLang(const AIdent: string): string; overload;
    function GetLang(const AIdent: Integer): string; overload;
    function GetItemLang(const AItemIdent: string): string;
    procedure ChangeLanguage;
    function LanguageName: string;
  end;

var
  Language: TLanguage;

implementation

uses
  System.SysUtils,
  System.JSON,
  Vcl.Dialogs,
  Trollhunter.Zip,
  Trollhunter.Utils,
  Trollhunter.Error,
  Trollhunter.Creatures,
  Dragonhunter.MainForm,
  Trollhunter.Item.Pattern;

var
  LanguageString: TLanguageString;

  { TLanguageString }

procedure TLanguageString.Add(const AId, AEn, ARu: string);
begin
  FId.Add(AId);
  FEn.Add(AEn);
  FRu.Add(ARu);
end;

procedure TLanguageString.Clear;
begin
  FId.Clear;
  FEn.Clear;
  FRu.Clear;
end;

constructor TLanguageString.Create;
begin
  FId := TStringList.Create;
  FEn := TStringList.Create;
  FRu := TStringList.Create;
end;

destructor TLanguageString.Destroy;
begin
  FreeAndNil(FId);
  FreeAndNil(FEn);
  FreeAndNil(FRu);
  inherited;
end;

{ TLanguage }

procedure TLanguage.ChangeLanguage;
begin
  if (FCurrentLanguageIndex = 0) then
    FCurrentLanguageIndex := 1
  else
    FCurrentLanguageIndex := 0;
end;

constructor TLanguage.Create;
begin
  LanguageString := TLanguageString.Create;
  FCurrentLanguageIndex := 0;
end;

destructor TLanguage.Destroy;
begin
  FreeAndNil(LanguageString);
  inherited;
end;

function TLanguage.GetLang(const AIdent: Integer): string;
begin
  Result := GetLang(AIdent.ToString);
end;

function TLanguage.GetLang(const AIdent: string): string;
var
  I: Integer;
begin
  Result := '';
  I := LanguageString.FId.IndexOf(AIdent);
  if I < 0 then
    Exit;
  if (FCurrentLanguageIndex = 0) then
    Result := LanguageString.En[I]
  else
    Result := LanguageString.Ru[I];
end;

function TLanguage.GetItemLang(const AItemIdent: string): string;
var
  LColorTag, LItemIndex: Integer;
  LColorPrefix: string;
begin
  Result := '';
  LItemIndex := Items.ItemIndex(AItemIdent);
  // Scrolls and Potions
  LColorTag := ItemPatterns.Patterns[LItemIndex].ColorTag;
  with Creatures.Character do
  begin
    if (LColorTag > 0) and
      (ItemPatterns.Patterns[LItemIndex].Category = 'POTION') and
      not Potions.IsDefined(LColorTag) then
    begin
      Result := '#r' + Potions.GetColorName(LColorTag) + ' ' +
        Language.GetLang(222) + '$';
      Exit;
    end;
    if (LColorTag > 0) and
      (ItemPatterns.Patterns[LItemIndex].Category = 'SCROLL') and
      not Scrolls.IsDefined(LColorTag) then
    begin
      Result := '#r' + Language.GetLang(221) + ' ' + '"' +
        Scrolls.GetName(LColorTag) + '"';
      Exit;
    end;
  end;
  // Items
  if ItemPatterns.Patterns[LItemIndex].Category = 'POTION' then
    LColorPrefix := '#g'
  else if ItemPatterns.Patterns[LItemIndex].Category = 'SCROLL' then
    LColorPrefix := '#b'
  else
    LColorPrefix := '#w';
  Result := LColorPrefix + GetLang(AItemIdent) + '$';
end;

function TLanguage.LanguageName: string;
begin
  case FCurrentLanguageIndex of
    0:
      Result := 'English';
    1:
      Result := 'Russian';
    2:
      Result := 'Ukrainian';
  end;
end;

procedure TLanguage.LoadFromResources;

  procedure LoadFromFile(const AFileName: string);
  var
    LStringList: TStringList;
    LJSONObject: TJSONObject;
    LJSONArray: TJSONArray;
    LZip: TZip;
    I: Integer;
    ID, En, Ru: string;
  begin
    try
      LStringList := TStringList.Create;
      try
        LZip := TZip.Create(MainForm);
        try
          LStringList.Text := LZip.ExtractTextFromFileUTF8
            (Path + 'resources.res', AFileName);
          LJSONArray := TJSONObject.ParseJSONValue(LStringList.Text)
            as TJSONArray;
          try
            for I := 0 to LJSONArray.Count - 1 do
            begin
              LJSONObject := LJSONArray.Items[I] as TJSONObject;
              ID := LJSONObject.GetValue('id').Value;
              En := LJSONObject.GetValue('en').Value;
              Ru := LJSONObject.GetValue('ru').Value;
              LanguageString.Add(ID, En, Ru);
            end;
          finally
            FreeAndNil(LJSONArray);
          end;
        finally
          FreeAndNil(LZip);
        end;
      finally
        FreeAndNil(LStringList);
      end;
    except
      on E: Exception do
        Error.Add('Lang.LoadFromFile', E.Message);
    end;
  end;

begin
  try
    if not FileExists(Path + 'resources.res') then
      Exit;
    LanguageString.Clear;
    LoadFromFile('languages.json');
    LoadFromFile('languages.maps.json');
    LoadFromFile('languages.items.json');
    LoadFromFile('languages.creatures.json');
  except
    on E: Exception do
      Error.Add('Lang.LoadFromResources', E.Message);
  end;
end;

initialization

Language := TLanguage.Create;
Language.LoadFromResources;

finalization

FreeAndNil(Language);

end.
