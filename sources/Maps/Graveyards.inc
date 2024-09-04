  (
  ID           : 'GRAVEYARDS';    
  Level        : 9;
  Items        : PotionLevel1 + PotionLevel2 + WeaponLevel1 + AmmuntLevel1 + RarityLevel1 + ScrollLevel1;
  Creatures    : 'SKELETON,SKELETONMAGE,DARKEYE,';
  Underground  : False;  
  Village      : False;
  GenID        : G_STONY_FIELD;
  DecorType    : dtStone;
  DecTypSize   : 50;
  DecTypCount  : 150;
  IsAutoEnt    : False;
  PrevMap      : 'BADLANDS';
  NextMap      : 'PLAINOFBONES';
  AltNextMap   : 'HALLOFTHEDEAD';
  IsAltMapEnt  : False;
  IsVillageEnt : False;
  IsTraps      : True;
  FloorTile    : tlGrass;
  FloorRes     : 'GRASS3';
  WallRes      : '';
  ),

  (
  ID           : 'HALLOFTHEDEAD';
  Level        : 10;
  Items        : PotionLevel1 + WeaponLevel1 + AmmuntLevel1 + AmmuntLevel2 + RarityLevel1 + ScrollLevel1;
  Creatures    : 'DARKEYE,BAT,BLUEBAT,CAVEBAT,';
  Underground  : True;
  Village      : False;
  GenID        : G_CAVES;
  DecorType    : dtBone;
  DecTypSize   : 45;
  DecTypCount  : 125;
  IsAutoEnt    : False;
  PrevMap      : 'GRAVEYARDS';
  NextMap      : '';
  AltNextMap   : '';
  IsAltMapEnt  : True;
  IsVillageEnt : False;
  IsTraps      : True;
  FloorTile    : tlFloor;
  FloorRes     : 'FLOOR1';
  WallRes      : 'WALL2';
  ),