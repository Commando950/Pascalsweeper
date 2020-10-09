unit main;

{$mode objfpc}{$H+}

interface

uses
     Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
     math, FileUtil, MMSystem;

type

     { TForm1 }

     TForm1 = class(TForm)
          BackgroundImage: TImage;
          GameBoard: TImage;
          procedure FormActivate(Sender: TObject);
          procedure FormCreate(Sender: TObject);
          procedure GameBoardMouseDown(Sender: TObject; Button: TMouseButton;
               Shift: TShiftState; X, Y: Integer);
          procedure GameBoardMouseMove(Sender: TObject; Shift: TShiftState; X,
               Y: Integer);
          procedure NewGame();
     private

     public

     end;

     GameTile = class
     public
          X: Integer;
          Y: Integer;
          Image: TImage;
          Flagged: Boolean;
          CharType: Char;
          constructor Create(ImageParent: TWinControl;Xpos,Ypos: Integer;TileType: Char);
          procedure Remove;
     end;
var
     Form1: TForm1;
     tileswidth: Integer;
     tilesheight: Integer;
     minecount: Integer;
     tiles: Array of Array of GameTile;
     labelarray: Array of TLabel;
     lasttile: GameTile;

implementation

{$R *.lfm}

constructor GameTile.Create(ImageParent: TWinControl;Xpos,Ypos: Integer;TileType: Char);
begin
     X := Xpos;
     Y := Ypos;
     CharType := TileType;
     Image := TImage.Create(ImageParent);
     with Image do begin
          Parent := ImageParent;
          Width := 20;
          Height := 20;
          Left := (X-1)*20;
          Top := (Y-1)*20;
          if CharType = 'C' then
               Picture.PNG.LoadFromFile('Images\Tile.png');
     end;
end;

procedure GameTile.Remove;
begin
     CharType := ' ';
     if Image <> nil then
          Image.Destroy;
     Image := nil;
end;

{ TForm1 }
procedure TForm1.FormCreate(Sender: TObject);
begin
end;

procedure CheckSurroundingTiles(X,Y:Integer);
var
     dx,dy:Integer;
     nearbymines:Integer;
begin
     //Check if there is mines here, don't reveal around it if there is!
     nearbymines := 0;
     for dx:=X-1 to X+1 do begin
          for dy:=Y-1 to Y+1 do begin
               if (dx > -1) and (dx < tileswidth) then
                    if (dy > -1) and (dy < tilesheight) then begin
                         if tiles[dx,dy].CharType = 'M' then begin
                              nearbymines := nearbymines + 1;
                         end;
                    end;
          end;
     end;
     if nearbymines = 0 then begin
          tiles[X,Y].Remove;
          for dx:=X-1 to X+1 do begin
               for dy:=Y-1 to Y+1 do begin
                    if (dx > -1) and (dx < tileswidth) then
                    if (dy > -1) and (dy < tilesheight) then begin
                         if tiles[dx,dy].CharType = 'C' then begin
                              CheckSurroundingTiles(dx,dy);
                         end;
                    end;
               end;
          end;
     end else begin
          if tiles[X,Y].CharType = 'C' then begin
               tiles[X,Y].Remove;
               //Lets create the shadow text.
               SetLength(labelarray, Length(labelarray)+1);
               labelarray[Length(labelarray)-1] := TLabel.Create(Form1);
               with labelarray[Length(labelarray)-1] do begin
                    Parent := Form1;
                    Caption := IntToStr(nearbymines);
                    AutoSize := False;
                    Width := 20;
                    Height := 20;
                    Font.Color := RGBToColor(0,0,0);
                    Font.Size := 16;
                    Font.Name := 'Impact';
                    Left := X*20;
                    Top := Y*20-2;
                    Alignment := taCenter;
               end;
               //Lets create the regular text.
               SetLength(labelarray, Length(labelarray)+1);
               labelarray[Length(labelarray)-1] := TLabel.Create(Form1);
               with labelarray[Length(labelarray)-1] do begin
                    Parent := Form1;
                    Caption := IntToStr(nearbymines);
                    AutoSize := False;
                    Width := 20;
                    Height := 20;
                    if nearbymines = 1 then
                         Font.Color := RGBToColor(0,0,255);
                    if nearbymines = 2 then
                         Font.Color := RGBToColor(0,255,0);
                    if nearbymines = 3 then
                         Font.Color := RGBToColor(255,255,0);
                    if nearbymines > 3 then
                         Font.Color := RGBToColor(255,0,0);
                    Font.Size := 14;
                    Font.Name := 'Impact';
                    Left := X*20;
                    Top := Y*20;
                    Alignment := taCenter;
               end;
          end;
     end;
end;

procedure TForm1.GameBoardMouseDown(Sender: TObject; Button: TMouseButton;
     Shift: TShiftState; X, Y: Integer);
var
     dx,dy: Integer;
     clearleft: Integer;
begin
     X:=floor(X/20);
     Y:=floor(Y/20);
     if (mbLeft = Button) then begin;
          if tiles[X,Y].Flagged = false then begin;
               if tiles[X,Y].CharType = 'C' then begin
                    CheckSurroundingTiles(X,Y);
                    clearleft := 0;
                    for dx:=0 to tileswidth-1 do begin
                         for dy:=0 to tilesheight-1 do begin
                              if tiles[dx,dy].CharType = 'C' then begin
                                   clearleft := clearleft + 1;
                                   break;
                              end;
                         end;
                    end;
                    if clearleft = 0 then begin
                         ShowMessage('You win!');
                         for x :=1 to Length(labelarray) do begin
                              labelarray[x-1].Free;//Remove old labels.
                         end;
                         for dx:=0 to tileswidth-1 do begin
                              for dy:=0 to tilesheight-1 do begin
                                   tiles[dx,dy].Remove;
                              end;
                         end;
                         Form1.NewGame();
                    end;
               end;
          end;
          if tiles[X,Y].CharType = 'M' then begin
               for dx:=0 to tileswidth-1 do begin
                    for dy:=0 to tilesheight-1 do begin
                         if tiles[dx,dy].CharType = 'M' then begin
                              tiles[dx,dy].Image.Picture.PNG.LoadFromFile('Images\Mine.png');
                         end;
                    end;
               end;
               tiles[X,Y].Image.Picture.LoadFromFile('Images\Mine-Explode.png');
               sndPlaySound('explosion.wav', snd_Async);
               ShowMessage('You lose!');
               for x :=1 to Length(labelarray) do begin
                    labelarray[x-1].Free;//Remove old labels.
               end;
               for dx:=0 to tileswidth-1 do begin
                    for dy:=0 to tilesheight-1 do begin
                         tiles[dx,dy].Remove;
                    end;
               end;
               Form1.NewGame();
          end;
     end;
     if (mbRight = Button) then begin
          if tiles[X,Y].CharType <> ' ' then begin
               if tiles[X,Y].Flagged = false then begin
                    tiles[X,Y].Flagged := true;
                    tiles[X,Y].Image.Picture.PNG.LoadFromFile('Images\Flag.png');
               end else begin
                    tiles[X,Y].Flagged := false;
                    tiles[X,Y].Image.Picture.PNG.LoadFromFile('Images\Tile.png');
               end;
          end;
     end;
end;

procedure TForm1.GameBoardMouseMove(Sender: TObject; Shift: TShiftState; X,
     Y: Integer);
begin
     X:=floor(X/20);
     Y:=floor(Y/20);
     if tiles[X,Y].Image <> nil then begin
          if LastTile <> nil then
               if LastTile.Image <> nil then
                    if (LastTile.Flagged = false) then begin;
                         LastTile.Image.Picture.PNG.LoadFromFile('Images\Tile.png');
                    end else begin
                         LastTile.Image.Picture.PNG.LoadFromFile('Images\Flag.png');
                    end;
          LastTile := tiles[X,Y];
          if (tiles[X,Y].Flagged = false) then begin;
               tiles[X,Y].Image.Picture.PNG.LoadFromFile('Images\Tile-Highlight.png');
          end else begin
               tiles[X,Y].Image.Picture.PNG.LoadFromFile('Images\Flag-Highlight.png');
          end;
     end;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
     NewGame();
end;

procedure TForm1.NewGame();
var
     x,y,number: Integer;
     BackgroundImages: TStringList;
begin
     Randomize;
     BackgroundImages := TStringList.Create;
     FindAllFiles(BackgroundImages, 'Backgrounds\', '*.png;*.bmp;*.jpg;', true); //find e.g. all pascal sourcefiles
     if BackgroundImages.Count > 0 then
          BackgroundImage.Picture.LoadFromFile(BackgroundImages[Random(BackgroundImages.Count)]);
     tileswidth := width Div 20;
     tilesheight := height Div 20;
     minecount := Round((tileswidth*tilesheight) Div 6);
     SetLength(tiles, tileswidth, tilesheight); //Set the length of the array.
     SetLength(labelarray,0);
     for x :=1 to tileswidth do begin
          for y :=1 to tilesheight do begin
               if tiles[x-1,y-1] <> nil then
                    tiles[x-1,y-1].Destroy;
               tiles[x-1,y-1] := nil;
               tiles[x-1,y-1] := GameTile.Create(Self,x,y,'C');
          end;
     end;
     number := 0;
     while number < minecount do begin
          x := random(tileswidth);
          y := random(tilesheight);
          if tiles[x,y].CharType = 'C' then begin
               tiles[x,y].CharType := 'M';
               number := number + 1;
          end;
     end;
     GameBoard.BringToFront;
     ShowMessage('Game Ready!');
end;

end.

