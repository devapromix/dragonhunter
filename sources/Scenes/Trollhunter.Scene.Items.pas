unit Trollhunter.Scene.Items;

interface

uses
  Classes,
  Graphics,
  Windows,
  Trollhunter.Scene,
  Trollhunter.Scene.BaseGame;

type
  TSceneItems = class(TSceneBaseGame)
  private
    CursorPos: Integer;
    Icon: Graphics.TBitmap;
  public
    procedure KeyPress(var Key: Char); override;
    procedure Render(); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneItems: TSceneItems;

implementation

uses
  SysUtils,
  Trollhunter.Scene.Game,
  Trollhunter.Scenes,
  Trollhunter.Error,
  Trollhunter.Graph,
  Dragonhunter.Item,
  Trollhunter.Creatures,
  Dragonhunter.Color,
  Dragonhunter.Utils,
  Trollhunter.Lang,
  Dragonhunter.Scene.Inv,
  Trollhunter.Item.Pattern;

{ TSceneItem }

constructor TSceneItems.Create;
begin
  inherited Create(21);
  Icon := Graphics.TBitmap.Create;
  CursorPos := 1;
end;

destructor TSceneItems.Destroy;
begin
  Icon.Free;
  inherited;
end;

procedure TSceneItems.KeyDown(var Key: Word; Shift: TShiftState);
var
  LItemIndex, LCount: Integer;
  LKey: Word;
begin
  inherited;
  try
    case Key of
      38, 40:
        begin
          LCount := Items.CellItemsCount(Creatures.Character.Pos.X,
            Creatures.Character.Pos.Y);
          if (LCount > 0) then
          begin
            CursorPos := CursorPos + (Key - 39);
            CursorPos := ClampCycle(CursorPos, 1, LCount);
            Render;
          end;
        end;
      32:
        begin
          Items.PickupAll;
          Scenes.Scene := SceneGame
        end;
      8:
        Scenes.Scene := SceneInv;
      13:
        begin
          LCount := Items.CellItemsCount(Creatures.Character.Pos.X,
            Creatures.Character.Pos.Y);
          if (LCount > 0) then
          begin
            LKey := (ord('A') + CursorPos) - 1;
            KeyDown(LKey, Shift);
          end;
        end;
      ord('A') .. ord('Z'):
        begin
          LItemIndex := (Key - (ord('A'))) + 1;
          if (LItemIndex <= Items.CellItemsCount(Creatures.Character.Pos.X,
            Creatures.Character.Pos.Y)) then
          begin
            Items.Pickup(LItemIndex);
            if (Items.CellItemsCount(Creatures.Character.Pos.X,
              Creatures.Character.Pos.Y) = 0) then
              Scenes.Scene := SceneGame
            else
              Render;
          end;
        end;
    end;
  except
    on E: Exception do
      Error.Add('SceneItems.KeyDown (#' + IntToStr(Key) + ')', E.Message);
  end;
end;

procedure TSceneItems.KeyPress(var Key: Char);
begin
  inherited;

end;

procedure TSceneItems.Render;
var
  Tileset: Graphics.TBitmap;
  I, Y, LCount, V: Integer;
  S, ID: string;
begin
  inherited;
  Tileset := Graphics.TBitmap.Create;
  try
    Y := 2;
    with Graph.Surface.Canvas do
    begin
      LCount := Items.CellItemsCount(Creatures.Character.Pos.X,
        Creatures.Character.Pos.Y);
      if (LCount > 0) and (Length(Items.Item) > 0) then
        for I := 0 to High(Items.Item) do
          if (Items.Item[I].Pos.X = Creatures.Character.Pos.X) and
            (Items.Item[I].Pos.Y = Creatures.Character.Pos.Y) then
          begin
            CursorPos := Clamp(CursorPos, 1, LCount);
            ID := Items.Item[I].Name;
            if (ID = '') then
              Continue;
            V := Items.ItemIndex(ID);
            S := Chr((Y - 1) + 96) + '.';
            Font.Color := clSilver;
            if (CursorPos = Y - 1) then
            begin
              Font.Style := [fsBold];
              Graph.RenderMenuLine(Y, 0, False, 1, cDkGray);
            end
            else
            begin
              Font.Style := [];
            end;
            Graph.Text.DrawOut(1, Y, S);
            if (ItemPatterns.Patterns[V].Sprite = '') then
              Tileset.Handle := Windows.LoadBitmap(hInstance, PChar(ID))
            else
              Tileset.Handle := Windows.LoadBitmap(hInstance,
                PChar(ItemPatterns.Patterns[V].Sprite));
            Graph.BitmapFromTileset(Icon, Tileset, 0);
            Items.Colors(Icon, V);
            ScaleBmp(Icon, Graph.CharHeight, Graph.CharHeight);
            Icon.Transparent := True;
            Draw(Graph.CharWidth * 3, Y * Graph.CharHeight, Icon);
            Items.SetColor(V);
            if ((ItemPatterns.Patterns[V].MaxTough > 0) and
              (Items.Item[I].Prop.Tough <= 0)) then
              Font.Color := cRed;
            Graph.Text.DrawText(5, Y,
              Language.GetItemLang(ItemPatterns.Patterns[V].ID) +
              Items.GetItemProp(Items.Item[I].Count, Items.Item[I].Prop.Tough,
              I, V) + Items.GetWeight(V));
            Inc(Y);
          end;
      Items.RenderPCInvStat(Y);
      if (LCount = 1) then
        Graph.Text.BarOut('enter, a', Language.GetLang(26), False)
      else if (LCount > 1) then
        Graph.Text.BarOut('enter, a-' + Chr(96 + LCount),
          Language.GetLang(26), False);
      Graph.Text.BarOut('backspace', Language.GetLang(25), False);
      Graph.Text.BarOut('space', Language.GetLang(50), False);
    end;
    Graph.Render;
    Tileset.Free;
  except
    on E: Exception do
      Error.Add('SceneItems.Render', E.Message);
  end;
end;

initialization

SceneItems := TSceneItems.Create;

finalization

SceneItems.Free;

end.
