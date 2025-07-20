unit Trollhunter.Inv;

interface

uses
  Classes;

type
  TSlot = 1 .. 26;

type
  TRecInv = record
    Ident: string;
    Stack: Boolean;
    Doll: Boolean;
    Count: Integer;
    Weight: Integer;
    Tough: Integer;
  end;

  TInv = class(TObject)
  private
    FItem: array [TSlot] of TRecInv;
    FMaxCount: Integer;
    FMaxWeight: Integer;
    function GetSlot(const AIdent: string; var AExitFlag: Boolean): Integer;
    procedure SetMaxCount(Value: Integer);
    procedure SetMaxWeight(Value: Integer);
  public
    constructor Create(const AMaxCount, AMaxWeight: Integer);
    destructor Destroy; override;
    property MaxCount: Integer read FMaxCount write SetMaxCount;
    property MaxWeight: Integer read FMaxWeight write SetMaxWeight;
    procedure Clear(AMaxCount, AMaxWeight: Integer); overload;
    procedure Clear; overload;
    procedure Clear(const ASlot: Integer); overload;
    procedure SetTough(const ASlot: TSlot; ATough: Integer);
    function Add(const AIdent: string; ACount, AWeight, ATough: Integer;
      AStack: Boolean): Boolean;
    function Del(const AIdent: string; const ACount: Integer = 1)
      : Boolean; overload;
    function Del(const ASlot: TSlot; const ACount: Integer = 1)
      : Boolean; overload;
    function Count: Integer;
    function Weight: Integer;
    function GetIdent(const ASlot: Integer): string;
    function GetCount(const ASlot: Integer): Integer; overload;
    function GetCount(const AIdent: string): Integer; overload;
    function GetTough(const ASlot: Integer): Integer;
    function GetDoll(I: Integer): Boolean;
    function GetStack(I: Integer): Boolean;
    function GetWeight(const ASlot: Integer): Integer;
    function GetItemWeight(const ASlot: Integer): Integer;
  end;

  TAdvInv = class(TInv)
  private
    FStringList: TStringList;
    procedure Save;
    procedure Load;
    function GetText: string;
    procedure SetText(const Value: string);
  public
    property Text: string read GetText write SetText;
    function Equip(ASlot: Integer): Boolean;
    function UnEquip(ASlot: Integer): Boolean;
    constructor Create(AMaxCount, AMaxWeight: Integer); overload;
    constructor Create; overload;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  Dragonhunter.Utils;

constructor TInv.Create(const AMaxCount, AMaxWeight: Integer);
begin
  Clear(AMaxCount, AMaxWeight);
end;

destructor TInv.Destroy;
begin

end;

function TInv.GetIdent(const ASlot: Integer): string;
begin
  Result := FItem[ASlot].Ident;
end;

function TInv.GetCount(const ASlot: Integer): Integer;
begin
  Result := FItem[ASlot].Count;
  if (Result < 0) then
    Result := 0;
end;

function TInv.GetCount(const AIdent: string): Integer;
var
  LSlot: TSlot;
  LExitFlag: Boolean;
begin
  Result := 0;
  if (AIdent = '') then
    Exit;
  LSlot := GetSlot(AIdent, LExitFlag);
  if LExitFlag then
    Exit;
  Result := GetCount(LSlot);
end;

function TInv.GetWeight(const ASlot: Integer): Integer;
begin
  Result := FItem[ASlot].Weight * FItem[ASlot].Count;
  if (Result < 0) then
    Result := 0;
end;

function TInv.GetItemWeight(const ASlot: Integer): Integer;
begin
  Result := FItem[ASlot].Weight;
  if (Result < 0) then
    Result := 0;
end;

function TInv.GetTough(const ASlot: Integer): Integer;
begin
  Result := FItem[ASlot].Tough;
  if (Result < 0) then
    Result := 0;
end;

procedure TInv.SetTough(const ASlot: TSlot; ATough: Integer);
begin
  if (ATough < 0) then
    ATough := 0;
  FItem[ASlot].Tough := ATough;
end;

function TInv.GetDoll(I: Integer): Boolean;
begin
  Result := FItem[I].Doll;
end;

function TInv.GetStack(I: Integer): Boolean;
begin
  Result := FItem[I].Stack;
end;

procedure TInv.Clear(AMaxCount, AMaxWeight: Integer);
var
  LSlot: TSlot;
begin
  MaxCount := AMaxCount;
  MaxWeight := AMaxWeight;
  for LSlot := 1 to 26 do
    Clear(LSlot);
end;

procedure TInv.Clear;
var
  LSlot: TSlot;
begin
  for LSlot := 1 to 26 do
    Clear(LSlot);
end;

procedure TInv.Clear(const ASlot: Integer);
begin
  FItem[ASlot].Ident := '';
  FItem[ASlot].Count := 0;
  FItem[ASlot].Weight := 0;
  FItem[ASlot].Tough := 0;
  FItem[ASlot].Stack := False;
  FItem[ASlot].Doll := False;
end;

function TInv.GetSlot(const AIdent: string; var AExitFlag: Boolean): Integer;
var
  LSlot: TSlot;
begin
  Result := 1;
  AExitFlag := True;
  for LSlot := 1 to 26 do
    if (FItem[LSlot].Ident = AIdent) then
    begin
      Result := LSlot;
      AExitFlag := False;
      Exit;
    end;
end;

function TInv.Count: Integer;
var
  LSlot: TSlot;
  LCount: Integer;
begin
  LCount := 0;
  for LSlot := 1 to 26 do
    if (FItem[LSlot].Ident <> '') then
      LCount := LCount + 1;
  Result := LCount;
  if (Result < 0) then
    Result := 0;
end;

function TInv.Weight: Integer;
var
  LSlot: TSlot;
  FWeight: Integer;
begin
  FWeight := 0;
  for LSlot := 1 to 26 do
    if (FItem[LSlot].Ident <> '') then
      FWeight := FWeight + (FItem[LSlot].Weight * FItem[LSlot].Count);
  Result := FWeight;
  if (Result < 0) then
    Result := 0;
end;

function TInv.Add(const AIdent: string; ACount, AWeight, ATough: Integer;
  AStack: Boolean): Boolean;
var
  LSlot: TSlot;
  LExitFlag: Boolean;
begin
  Result := False;
  if (ACount <= 0) then
    Exit;
  LSlot := GetSlot(AIdent, LExitFlag);
  if LExitFlag or not AStack then
  begin
    LSlot := GetSlot('', LExitFlag);
    if LExitFlag then
      Exit;
  end;
  if (Self.Weight >= MaxWeight) then
    Exit;
  if (FItem[LSlot].Count = 0) and (Self.Count >= MaxCount) then
    Exit;
  FItem[LSlot].Ident := AIdent;
  FItem[LSlot].Weight := AWeight;
  FItem[LSlot].Stack := AStack;
  FItem[LSlot].Tough := ATough;
  FItem[LSlot].Count := FItem[LSlot].Count + ACount;
  Result := True;
end;

function TInv.Del(const ASlot: TSlot; const ACount: Integer): Boolean;
var
  LSlot: TSlot;
begin
  Result := False;
  if (FItem[ASlot].Count = 0) or (FItem[ASlot].Count < ACount) then
    Exit;

  FItem[ASlot].Count := FItem[ASlot].Count - ACount;
  if (FItem[ASlot].Count = 0) then
    Clear(ASlot);
  Result := True;

  for LSlot := ASlot to Count do
  begin
    if (FItem[LSlot].Ident = '') then
    begin
      FItem[LSlot] := FItem[LSlot + 1];
      Clear(LSlot + 1);
    end;
  end;
end;

function TInv.Del(const AIdent: string; const ACount: Integer): Boolean;
var
  LSlot: TSlot;
  LExitFlag: Boolean;
begin
  Result := False;
  LSlot := GetSlot(AIdent, LExitFlag);
  if LExitFlag then
    Exit;
  Del(LSlot, ACount);
end;

{ TAdvInv }

constructor TAdvInv.Create(AMaxCount, AMaxWeight: Integer);
begin
  inherited Create(AMaxCount, AMaxWeight);
  FStringList := TStringList.Create;
end;

constructor TAdvInv.Create;
begin
  Create(0, 0);
end;

destructor TAdvInv.Destroy;
begin
  FStringList.Free;
  inherited;
end;

procedure TAdvInv.Load;
var
  LSlot: TSlot;
  LIndex: Integer;
  LExpString: TExplodeResult;
begin
  LSlot := 1;
  LExpString := nil;
  Clear(MaxCount, MaxWeight);
  for LIndex := 0 to FStringList.Count - 1 do
  begin
    LExpString := Explode('/', FStringList[LIndex]);
    if (Trim(LExpString[0]) <> '') then
    begin
      FItem[LSlot].Ident := LExpString[0];
      FItem[LSlot].Count := StrToInt(LExpString[1]);
      FItem[LSlot].Weight := StrToInt(LExpString[2]);
      FItem[LSlot].Tough := StrToInt(LExpString[3]);
      FItem[LSlot].Stack := (FItem[LSlot].Count > 1);
      FItem[LSlot].Doll := ToBoo(LExpString[4]);
    end;
    Inc(LSlot);
  end;
end;

procedure TAdvInv.Save;
var
  LSlot: TSlot;
begin
  FStringList.Clear;
  for LSlot := 1 to 26 do
    with FItem[LSlot] do
      FStringList.Append(Format('%s/%d/%d/%d/%d', [Ident, Count, Weight, Tough,
        ToInt(Doll)]));
end;

function TAdvInv.Equip(ASlot: Integer): Boolean;
begin
  // Result := False;
  // if not FItem[I].Stack and (FItem[I].Count = 1) then
  begin
    FItem[ASlot].Doll := True;
    Result := True;
  end;
end;

function TAdvInv.UnEquip(ASlot: Integer): Boolean;
begin
  Result := False;
  if FItem[ASlot].Doll { and not FItem[I].Stack and (FItem[I].Count = 1) } then
  begin
    FItem[ASlot].Doll := False;
    Result := True;
  end;
end;

procedure TInv.SetMaxCount(Value: Integer);
begin
  if (Value < 0) then
    Value := 0;
  if (Value > 26) then
    Value := 26;
  FMaxCount := Value;
end;

procedure TInv.SetMaxWeight(Value: Integer);
begin
  if (Value < 0) then
    Value := 0;
  if (Value > 500) then
    Value := 500;
  FMaxWeight := Value;
end;

function TAdvInv.GetText: string;
begin
  Self.Save;
  Result := FStringList.Text;
end;

procedure TAdvInv.SetText(const Value: string);
begin
  FStringList.Text := Value;
  Self.Load;
end;

end.
