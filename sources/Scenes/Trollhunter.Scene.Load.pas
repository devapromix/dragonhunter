unit Trollhunter.Scene.Load;

interface

uses
  Classes,
  Trollhunter.Scene,
  Trollhunter.Scene.BaseMenu;

type
  TSceneLoad = class(TSceneBaseMenu)
  private
    FCursorPos: Integer;
    FStringList: TStringList;
    function Count: Byte;
  public
    procedure Render(); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure ReadSaveDir();
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneLoad: TSceneLoad;

implementation

uses
  SysUtils,
  Graphics,
  Trollhunter.Graph,
  Trollhunter.Scenes,
  Dragonhunter.Scene.Menu,
  Trollhunter.Utils,
  Dragonhunter.Color,
  Dragonhunter.MainForm,
  Trollhunter.Game,
  Trollhunter.Creatures,
  Trollhunter.Scene.Game,
  Trollhunter.Error,
  Trollhunter.Lang;

{ TSceneLoad }

function TSceneLoad.Count: Byte;
begin
  Result := FStringList.Count;
  if (Result > 26) then
    Result := 26;
end;

constructor TSceneLoad.Create;
begin
  inherited Create(1);
  FStringList := TStringList.Create;
  FCursorPos := 1;
end;

destructor TSceneLoad.Destroy;
begin
  FStringList.Free;
  inherited;
end;

procedure TSceneLoad.KeyDown(var Key: Word; Shift: TShiftState);
var
  I: Byte;
  K: Word;
  C: Integer;
begin
  inherited;
  try
    case Key of
      38, 40:
        begin
          C := Count;
          if (C > 0) then
          begin
            FCursorPos := FCursorPos + (Key - 39);
            FCursorPos := ClampCycle(FCursorPos, 1, C);
            Render;
          end;
        end;
      13:
        begin
          C := Count;
          if (C > 0) then
          begin
            K := (ord('A') + FCursorPos) - 1;
            KeyDown(K, Shift);
          end;
        end;
      ord('A') .. ord('Z'):
        begin
          I := Key - (ord('A'));
          if (I < Count) then
          begin
            SceneGame.Free;
            SceneGame := TSceneGame.Create;
            Creatures.Character.Name := FStringList[I];
            Game.Load();
            Graph.Messagebar.Clear;
            Graph.Messagebar.Add(Format(Language.GetLang(20),
              [Creatures.Character.Name, MainForm.Caption]));
            Scenes.Scene := SceneGame;
          end;
        end;
    end;
  except
    on E: Exception do
      Error.Add('SceneLoad.KeyDown (#' + IntToStr(Key) + ')', E.Message);
  end;
end;

procedure TSceneLoad.KeyPress(var Key: Char);
begin
  inherited;

end;

procedure TSceneLoad.ReadSaveDir;
var
  SR: TSearchRec;
  S: string;
begin
  try
    FStringList.Clear;
    if (FindFirst(Path + '\save\*.sav', faAnyFile, SR) = 0) then
    begin
      repeat
        S := Trim(SR.Name);
        if (S = '') then
          Continue;
        Delete(S, Length(S) - 3, 4);
        FStringList.Append(S);
      until FindNext(SR) <> 0;
      FindClose(SR);
    end;
    FStringList.Sort;
  except
    on E: Exception do
      Error.Add('SceneLoad.ReadSaveDir', E.Message);
  end;
end;

procedure TSceneLoad.Render;
const
  N: array [0 .. 2] of Byte = (30, 45, 60);
var
  C, I, Y, LMax, R: Integer;
  S: string;
  P: TPCInfo;
begin
  inherited;
  try
    with Graph.Surface.Canvas do
    begin
      C := Count;
      R := Graph.Width div (Graph.CharWidth * 6);
      for I := 0 to C - 1 do
      begin
        if (I > 25) then
          Break;
        Y := (I + 3) * Graph.CharHeight;
        S := Chr(I + 97) + '.';
        FCursorPos := Clamp(FCursorPos, 1, C);
        if (FCursorPos = I + 1) then
        begin
          Font.Style := [fsBold];
          Font.Color := cAcColor;
          Graph.RenderMenuLine(I + 3, 0, False, 1, cDkGray);
        end
        else
        begin
          Font.Style := [];
          Font.Color := cBgColor;
        end;
        P := Game.GetPCInfo(Path + 'save\' + FStringList[I] + '.sav');
        TextOut((Graph.CharWidth * 3) - TextWidth(S), Y, S);
        TextOut(Graph.CharWidth * 3, Y, FStringList[I]);
        TextOut(Graph.CharWidth * R, Y, IntToStr(P.Level));
        TextOut(Graph.CharWidth * (R * 2), Y, IntToStr(P.Rating));
        // TextOut(Graph.CharWidth * (R * 3), Y, Language.GetStr(P.Dungeon));
        TextOut(Graph.Width - (Graph.CharWidth * 20), Y,
          GetFileDate(Path + 'save\' + FStringList[I] + '.sav'));
      end;
      Font.Style := [];
      if (Count > 0) then
      begin
        Font.Color := cDkYellow;
        TextOut(Graph.CharWidth, Graph.CharHeight * 2, '#');
        TextOut(Graph.CharWidth * 3, Graph.CharHeight * 2,
          Language.GetLang(37));
        TextOut(Graph.CharWidth * R, Graph.CharHeight * 2,
          Language.GetLang(30));
        TextOut(Graph.CharWidth * (R * 2), Graph.CharHeight * 2,
          Language.GetLang(36));
        TextOut(Graph.CharWidth * (R * 3), Graph.CharHeight * 2,
          Language.GetLang(39));
        TextOut(Graph.Width - (Graph.CharWidth * 20), Graph.CharHeight * 2,
          Language.GetLang(140));
      end;
      if (Count = 1) then
        Graph.Text.BarOut('a', Language.GetLang(28), False)
      else if (Count > 1) then
        Graph.Text.BarOut('a-' + Chr(96 + Count), Language.GetLang(28), False)
    end;
    Graph.Render;
  except
    on E: Exception do
      Error.Add('SceneLoad.Render', E.Message);
  end;
end;

initialization

SceneLoad := TSceneLoad.Create;

finalization

SceneLoad.Free;

end.
