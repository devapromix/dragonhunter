unit Dragonhunter.Effect;

interface

uses
  Graphics;

type
  TEffectEnum = (efBlind, efPoison, efLife, efMana, efWizardEye, efWebbed,
    efHypervision);

const
  EffectName: array [TEffectEnum] of string = ('Blind', 'Poison', 'VialOfLife',
    'VialOfMana', 'WizardEye', 'Webbed', 'Hypervision');

type
  TEffects = class(TObject)
  private
    Surface: Graphics.TBitmap;
    function GetEffectImage(const I: Integer): Graphics.TBitmap;
  public
    Image: array [TEffectEnum] of Graphics.TBitmap;
    constructor Create;
    destructor Destroy; override;
    procedure Render;
  end;

implementation

uses
  Windows,
  System.SysUtils,
  Trollhunter.Error,
  Trollhunter.Graph,
  Trollhunter.TempSys,
  Dragonhunter.Character,
  Trollhunter.Game,
  Trollhunter.Creatures,
  Trollhunter.Utils;

{ TEffects }

constructor TEffects.Create;
var
  LEffectEnum: TEffectEnum;
  Tileset: Graphics.TBitmap;
begin
  Surface := Graphics.TBitmap.Create;
  Tileset := Graphics.TBitmap.Create;
  Tileset.Handle := Windows.LoadBitmap(hInstance, 'EFFECTS');
  for LEffectEnum := Low(TEffectEnum) to High(TEffectEnum) do
  begin
    Image[LEffectEnum] := Graphics.TBitmap.Create;
    Graph.BitmapFromTileset(Image[LEffectEnum], Tileset, Ord(LEffectEnum));
    Image[LEffectEnum].Transparent := False;
  end;
  Tileset.Free;
end;

destructor TEffects.Destroy;
var
  LEffectEnum: TEffectEnum;
begin
  for LEffectEnum := Low(TEffectEnum) to High(TEffectEnum) do
    Image[LEffectEnum].Free;
  Surface.Free;
  inherited;
end;

function TEffects.GetEffectImage(const I: Integer): Graphics.TBitmap;
var
  LEffectName: string;
  LEffectEnum: TEffectEnum;
begin
  LEffectName := Creatures.Character.TempSys.VarName(I);
  for LEffectEnum := Low(TEffectEnum) to High(TEffectEnum) do
    if (LEffectName = UpperCase(EffectName[LEffectEnum])) then
    begin
      Result := Image[LEffectEnum];
      Break;
    end;
  ScaleBMP(Result, TileSize, TileSize);
end;

procedure TEffects.Render;
var
  I, Left: Integer;
begin
  if Creatures.Character.TempSys.Count > 0 then
  begin
    Surface.Width := Creatures.Character.TempSys.Count * TileSize;
    Surface.Height := TileSize;
    for I := 0 to Creatures.Character.TempSys.Count - 1 do
      Surface.Canvas.Draw(I * TileSize, 0, GetEffectImage(I));
    Left := ((Graph.Width - Graph.PW) div 2) - (Surface.Width div 2);
    Graph.Surface.Canvas.Draw(Left, Graph.Surface.Canvas.Font.Size + 8,
      Surface);
  end;
end;

end.
