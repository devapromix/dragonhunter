unit Dragonhunter.Wander;

interface

uses
  System.Types;

type
  TWander = class(TObject)
  public
  var
    WanderMode: Boolean;
  private
    FTarget: TPoint;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Finish(const IsClear: Boolean = False);
    procedure Process;
    property Target: TPoint read FTarget write FTarget;
    function IsFound: Boolean;
    procedure Render;
  end;

var
  Wander: TWander;

implementation

{ TWander }

uses
  System.Math,
  System.SysUtils,
  Vcl.Graphics,
  Dragonhunter.Utils,
  Trollhunter.Graph,
  Trollhunter.Creatures,
  Dragonhunter.Terminal,
  Dragonhunter.AStar,
  Dragonhunter.Map,
  Dragonhunter.Item,
  Dragonhunter.Color;

function IsFreeCell(AX, AY: Integer): Boolean; stdcall;
begin
  Result := Creatures.Character.FreeCell(AX, AY);
end;

constructor TWander.Create;
begin
  WanderMode := False;
end;

destructor TWander.Destroy;
begin

  inherited;
end;

procedure TWander.Finish(const IsClear: Boolean = False);
begin
  WanderMode := False;
  if IsClear then
  begin
    FTarget.X := 0;
    FTarget.Y := 0;
  end;
end;

procedure TWander.Process;
var
  NX, NY: Integer;
begin
  NX := 0;
  NY := 0;
  if not DoAStar(Map.Width, Map.Height, Creatures.Character.Pos.X,
    Creatures.Character.Pos.Y, FTarget.X, FTarget.Y, @IsFreeCell, NX, NY) then
    Exit;
  if (NX <= 0) and (NY <= 0) or IsFound then
  begin
    Finish;
    Exit;
  end;
  Creatures.Character.SetPosition(NX, NY);
end;

procedure TWander.Render;
var
  X, Y, DX, DY: Integer;
begin
  with Graph.Surface.Canvas do
  begin
    for X := Trollhunter.Creatures.Creatures.Character.Pos.X -
      Graph.RW to Trollhunter.Creatures.Creatures.Character.Pos.X + Graph.RW do
      for Y := Trollhunter.Creatures.Creatures.Character.Pos.Y -
        Graph.RH to Trollhunter.Creatures.Creatures.Character.Pos.Y +
        Graph.RH do
      begin
        if (X < 0) or (Y < 0) or (X > MapSide - 1) or (Y > MapSide - 1) then
          Continue;
        if ((Wander.Target.X <> 0) and (Wander.Target.Y <> 0)) then
          if ((Wander.Target.X = X) and (Wander.Target.Y = Y)) then
          begin
            DX := (X - (Trollhunter.Creatures.Creatures.Character.Pos.X -
              Graph.RW)) * TileSize;
            DY := (Y - (Trollhunter.Creatures.Creatures.Character.Pos.Y -
              Graph.RH)) * TileSize + Graph.CharHeight;
            Brush.Style := bsClear;
            Pen.Color := cLtYellow;
            Rectangle(DX, DY, DX + TileSize, DY + TileSize);
          end;
      end;
  end;

end;

function TWander.IsFound: Boolean;
var
  X, Y, I: Integer;
begin
  Result := False;
  with Creatures.Character do
  begin
    for X := Pos.X - GetRadius to Pos.X + GetRadius do
      for Y := Pos.Y - GetRadius to Pos.Y + GetRadius do
      begin
        if (X < 0) or (Y < 0) or (X > MapSide - 1) or (Y > MapSide - 1) then
          Continue;
        if (GetDist(Pos.X, Pos.Y, X, Y) > GetRadius - 1) then
          Continue;
        for I := High(Items.Item) downto 0 do
          if (X = Items.Item[I].Pos.X) and (Y = Items.Item[I].Pos.Y) then
          begin
            FTarget := Items.Item[I].Pos;
            Exit(True);
          end;
      end;
  end;
end;

procedure TWander.Start;
var
  LNextPoint: TPoint;
  I: Integer;
begin
  WanderMode := True;
  FTarget.X := 0;
  FTarget.Y := 0;
  repeat
    if Items.Count > 0 then
    begin
      I := RandomRange(0, Items.Count);
      FTarget.X := Items.Item[I].Pos.X;
      FTarget.Y := Items.Item[I].Pos.Y;
    end
    else
    begin
      FTarget.X := RandomRange(0, MapSide - 1);
      FTarget.Y := RandomRange(0, MapSide - 1);
    end;
  until Creatures.Character.FreeCell(FTarget.X, FTarget.Y);
end;

initialization

Wander := TWander.Create;

finalization

Wander.Free;

end.
