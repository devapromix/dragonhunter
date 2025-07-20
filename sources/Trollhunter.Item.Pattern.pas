unit Trollhunter.Item.Pattern;

interface

uses
  System.Classes,
  System.Generics.Collections;

type
  TItemPattern = class(TObject)
  private
    FId: string;
    FSprite: string;
    FRarity: string;
    FLevel: Integer;
    FColorTag: Integer;
    FColor: string;
    FIsStack: Boolean;
    FCategory: string;
    FScript: string;
    FMaxDamage: Integer;
    FProtect: Integer;
    FMinDamage: Integer;
    FTough: Integer;
    FMaxTough: Integer;
    FWeight: Integer;
    FManaCost: Integer;
    FMaxCount: Integer;
    FMinCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property Id: string read FId write FId;
    property Sprite: string read FSprite write FSprite;
    property Rarity: string read FRarity write FRarity;
    property Level: Integer read FLevel write FLevel;
    property ColorTag: Integer read FColorTag write FColorTag;
    property Color: string read FColor write FColor;
    property IsStack: Boolean read FIsStack write FIsStack;
    property Category: string read FCategory write FCategory;
    property Script: string read FScript write FScript;
    property MinDamage: Integer read FMinDamage write FMinDamage;
    property MaxDamage: Integer read FMaxDamage write FMaxDamage;
    property Protect: Integer read FProtect write FProtect;
    property Tough: Integer read FTough write FTough;
    property MaxTough: Integer read FMaxTough write FMaxTough;
    property Weight: Integer read FWeight write FWeight;
    property ManaCost: Integer read FManaCost write FManaCost;
    property MinCount: Integer read FMinCount write FMinCount;
    property MaxCount: Integer read FMaxCount write FMaxCount;

  end;

type
  TItemPatterns = class(TObject)
  private
    FPatterns: TObjectList<TItemPattern>;
    procedure Deserialize;
    procedure Serialize;
  public
    constructor Create;
    destructor Destroy; override;
    property Patterns: TObjectList<TItemPattern> read FPatterns write FPatterns;
    function GetPattern(const AIndex: Integer): TItemPattern;
  end;

var
  ItemPatterns: TItemPatterns;

implementation

uses
  System.SysUtils,
  System.JSON,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON,
  Trollhunter.Utils,
  Trollhunter.Log,
  Trollhunter.Lang,
  Trollhunter.Error,
  Dragonhunter.MainForm,
  Trollhunter.Zip,
  Dragonhunter.Map,
  Dragonhunter.Item;

{ TMapPattern }

constructor TItemPattern.Create;
begin

end;

destructor TItemPattern.Destroy;
begin

  inherited;
end;

{ TItemPatterns }

constructor TItemPatterns.Create;
begin
  FPatterns := TObjectList<TItemPattern>.Create;
end;

procedure TItemPatterns.Deserialize;
var
  LStringList: TStringList;
  LJSON: TJSONValue;
  LConfig: INeonConfiguration;
  LZip: TZip;
begin
  LStringList := TStringList.Create;
  LStringList.WriteBOM := False;
  LZip := TZip.Create(MainForm);
  try
    LStringList.Text := LZip.ExtractTextFromFile(Path + 'resources.res',
      'items.json');
    LJSON := TJSONObject.ParseJSONValue(LStringList.Text);
    try
      LConfig := TNeonConfiguration.Default;
      TNeon.JSONToObject(ItemPatterns, LJSON, LConfig);
    finally
      LJSON.Free;
    end;
  finally
    LStringList.Free;
    LZip.Free;
  end;
end;

destructor TItemPatterns.Destroy;
begin
  FreeAndNil(FPatterns);
  inherited;
end;

function TItemPatterns.GetPattern(const AIndex: Integer): TItemPattern;
begin
  Result := Patterns[AIndex];
end;

procedure TItemPatterns.Serialize;
var
  LStringList: TStringList;
  LJSON: TJSONValue;
begin
  LStringList := TStringList.Create;
  LStringList.WriteBOM := False;
  try
    LJSON := TNeon.ObjectToJSON(ItemPatterns);
    try
      LStringList.Text := TNeon.Print(LJSON, True);
      LStringList.SaveToFile(Path + 'items.json', TEncoding.UTF8);
    finally
      LJSON.Free;
    end;
  finally
    LStringList.Free;
  end;
end;

initialization

ItemPatterns := TItemPatterns.Create;
ItemPatterns.Deserialize;
// ItemPatterns.Serialize;

finalization

FreeAndNil(ItemPatterns);

end.
