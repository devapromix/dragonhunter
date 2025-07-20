unit Dragonhunter.MainForm;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  ShellAPI,
  ExtCtrls;

type
  TMainForm = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    Procedure WindowMessage(var Msg: TMessage); message WM_SYSCOMMAND;
    Procedure MouseClick(var Msg: TMessage); message WM_USER + 1;
  public
    { Public declarations }
    procedure ActionIcon(N: Integer; Icon: TIcon);
    Procedure OnMinimizeProc(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

uses
  Types,
  Trollhunter.Scenes,
  Trollhunter.Creatures,
  Trollhunter.Graph,
  Dragonhunter.Scene.Menu,
  Dragonhunter.Map,
  Trollhunter.Utils,
  Trollhunter.Screenshot,
  Trollhunter.Game,
  Dragonhunter.Scene.LevelUp,
  Dragonhunter.Wander,
  Trollhunter.Scene.Game;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Application.OnMinimize := OnMinimizeProc;
  Graph := TGraph.Create(GetParams.X, GetParams.Y, GetParamFontSize, Canvas);
  Scenes.Scene := SceneMenu;
end;

procedure TMainForm.FormPaint(Sender: TObject);
begin
  Scenes.Render;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Scenes.KeyDown(Key, Shift);
end;

procedure TMainForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Scenes.KeyPress(Key);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  Graph.Free;
  Game.Save;
end;

procedure TMainForm.ActionIcon(N: Integer; Icon: TIcon);
var
  LNotifyIconData: TNotifyIconData;
begin
  with LNotifyIconData do
  begin
    cbSize := System.SizeOf(LNotifyIconData);
    Wnd := MainForm.Handle;
    uID := 1;
    uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
    hicon := Icon.Handle;
    uCallbackMessage := WM_USER + 1;
    szTip := 'Dragonhunter';
  end;
  case N of
    1:
      Shell_NotifyIcon(Nim_Add, @LNotifyIconData);
    2:
      Shell_NotifyIcon(Nim_Delete, @LNotifyIconData);
    3:
      Shell_NotifyIcon(Nim_Modify, @LNotifyIconData);
  end;
end;

procedure TMainForm.MouseClick(var Msg: TMessage);
var
  LPoint: TPoint;
begin
  GetCursorPos(LPoint);
  case Msg.LParam of
    WM_RBUTTONUP:
      begin
        // SetForegroundWindow(Handle);
        // PopupMenu1.Popup(P.X, P.Y);
        PostMessage(Handle, WM_NULL, 0, 0);
      end;
    WM_LBUTTONUP, WM_LBUTTONDBLCLK:
      begin
        ActionIcon(2, Application.Icon);
        ShowWindow(Handle, SW_SHOWNORMAL);
        ShowWindow(Application.Handle, SW_SHOWNORMAL);
        SetForegroundWindow(Handle);
      end;
  end;
end;

procedure TMainForm.OnMinimizeProc(Sender: TObject);
begin
  PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
end;

procedure TMainForm.WindowMessage(var Msg: TMessage);
begin
  if Msg.WParam = SC_MINIMIZE then
  begin
    ActionIcon(1, Application.Icon);
    ShowWindow(Handle, SW_HIDE);
    ShowWindow(Application.Handle, SW_HIDE);
  end
  else
    inherited;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not ParamDebug then
    CanClose := (Scenes.Scene = SceneMenu);
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  if (Scenes.Scene = SceneMenu) then
    Scenes.Render;
  if (Scenes.Scene = SceneGame) and Wander.WanderMode then
  begin
    Wander.Process;
    Scenes.Render;
  end;
end;

{
  'Mage': "The Mage is a powerful fighter and a bit of a mystery to many who don't understand his powers. \
  He is very resourceful and can use his magic for more then just fighting. \
  Some people fear the Mages power and it may prove to be annoying when buying things from merchants.",

  'Warrior': "The Warrior is very tough and have been know to not only take hard blows but also deal heavy hits. \
  Most Warriors like swords but some have been known to use Battle Axes among other things. \
  He likes to fight up close with his opponent.",

  'Archer': "The Archer is a long range fighter. He likes to hit his pray from a far, out of the reaches of a sword. \
  Don't worry though he is also skilled with a short sword incase he misses or the enemy gets close to him.",

  'Assassin': "The Assassin likes the shadows and relies on stealth for surprise attacks. \
  He wields daggers and short swords and has throwing stars if needed."
}

end.
