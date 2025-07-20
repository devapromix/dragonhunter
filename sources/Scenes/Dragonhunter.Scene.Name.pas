unit Dragonhunter.Scene.Name;

interface

uses
  Classes,
  Trollhunter.Scene,
  Trollhunter.Scene.BaseMenu;

type
  TSceneName = class(TSceneBaseMenu)
  private const
    MAX_NAME_LENGTH = 15;
    VALID_CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-';
    procedure NewName;
    procedure DelChar;
    procedure AddChar(const AChar: Char);
    function GetPath: string;
  public
    procedure Render(); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneName: TSceneName;

implementation

uses
  SysUtils,
  Graphics,
  Dragonhunter.Terminal,
  Trollhunter.Creatures,
  Trollhunter.Scenes,
  Trollhunter.Scene.Game,
  Dragonhunter.Color,
  Trollhunter.Game,
  Dragonhunter.MainForm,
  Dragonhunter.Scene.Menu,
  Trollhunter.Name,
  Trollhunter.Utils,
  Trollhunter.Error,
  Trollhunter.Lang,
  Trollhunter.Scene.Race,
  Dragonhunter.Frame;

{ TSceneName }

procedure TSceneName.AddChar(const AChar: Char);
begin
  if (Length(Creatures.Character.Name) < MAX_NAME_LENGTH) then
  begin
    Creatures.Character.Name := Creatures.Character.Name + AChar;
    Render;
  end;
end;

constructor TSceneName.Create;
begin
  inherited Create(4);
end;

destructor TSceneName.Destroy;
begin

  inherited;
end;

procedure TSceneName.NewName;
var
  LName: string;
begin
  begin
    LName := Creatures.Character.Name;
    Game.New;
    Creatures.Character.Name := LName;
    SceneRace.MakePC;
    Scenes.Scene := SceneRace;
  end;
end;

procedure TSceneName.DelChar;
var
  LName: string;
begin
  if (Length(Creatures.Character.Name) > 0) then
  begin
    LName := Creatures.Character.Name;
    Delete(LName, Length(LName), 1);
    Creatures.Character.Name := LName;
    Render;
  end;
end;

function TSceneName.GetPath: string;
begin
  Result := Path + 'save\' + Creatures.Character.Name + '.sav';
end;

procedure TSceneName.KeyDown(var Key: Word; Shift: TShiftState);
var
  LName: TName;
begin
  inherited;
  try
    LName := TName.Create;
    try
      case Key of
        8:
          DelChar();
        13:
          begin
            if (Creatures.Character.Name <> '') then
            begin
              SceneGame.Free;
              SceneGame := TSceneGame.Create;
              if FileExists(Path + 'save\' + Creatures.Character.Name + '.sav')
              then
              begin
                Game.Load();
                Terminal.AddToMessagebar(Format(Language.GetLang(20),
                  [Creatures.Character.Name, MainForm.Caption]));
                Scenes.Scene := SceneGame;
              end
              else
                NewName;
            end
            else
            begin
              Creatures.Character.Name := LName.Gen();
              Render();
            end;
          end;
        32:
          begin
            Creatures.Character.Name := LName.Gen();
            Render();
          end;
      end;
    finally
      LName.Free;
    end;
  except
    on E: Exception do
      Error.Add('SceneName.KeyDown (#' + IntToStr(Key) + ')', E.Message);
  end;
end;

procedure TSceneName.Render;
var
  S, N: string;
  W, H, V: Integer;
  LPCInfo: TPCInfo;
  // F: Boolean;
begin
  inherited;
  try
    N := 'space';
    Terminal.TextColor(cBgColor);
    S := Language.GetLang(38) + #32 + Creatures.Character.Name + '_';
    W := Terminal.TextWidth(S);
    S := Language.GetLang(38);
    Terminal.NormalFont;
    H := Terminal.TextWidth(S);
    V := 0;
    if FileExists(GetPath) then
      V := 1;
    Terminal.TextOut((Terminal.Width div 2) - (W div 2),
      Terminal.Height div 2 - V, S);
    Terminal.BoldFont;
    Terminal.TextColor(cAcColor);
    S := #32 + Creatures.Character.Name + '_';
    Terminal.TextOut((Terminal.Width div 2) - (W div 2) + H,
      Terminal.Height div 2 - V, S);
    if (Creatures.Character.Name = '') then
      N := 'enter, ' + N;
    Terminal.BarOut(N, 48);

    if FileExists(GetPath) then
    begin
      LPCInfo := Game.GetPCInfo(GetPath);
      S := AnsiLowerCase(Language.GetLang(30) + ': ' + IntToStr(LPCInfo.Level) +
        ' | ' + Language.GetLang(36) + ': ' + IntToStr(LPCInfo.Rating) + ' | ' +
        Language.GetLang(140) + ': ' + GetFileDate(GetPath));
      Terminal.TextColor(cBgColor);
      W := Terminal.TextWidth(S);
      Terminal.TextOut((Terminal.Width div 2) - (W div 2),
        Terminal.Height div 2 + 1, S);
      Terminal.BarOut('enter', 1);
    end;

    Terminal.TextColor(cAcColor);
    Frame.Draw((Terminal.Width div 2) - 30, Terminal.Height div 2 - (V + 2), 60,
      (V * 2) + 5);
    Terminal.Render;
  except
    on E: Exception do
      Error.Add('SceneName.Render', E.Message);
  end;
end;

procedure TSceneName.KeyPress(var Key: Char);
begin
  if (Pos(Key, VALID_CHARS) > 0) then
    AddChar(Key);
end;

initialization

SceneName := TSceneName.Create;

finalization

SceneName.Free;

end.
