unit U_Hitsugaya;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, jpeg, ExtCtrls, ComCtrls, U_Classes, Buttons, pngimage, ShellApi,
  ImgList;

type
    TF_Hitsugaya = class(TForm)
    P_Spacer: TPanel;
    I_Logo: TImage;
    P_Mapping: TPanel;
    E_Path: TEdit;
    CB_Mapping: TCheckBox;
    L_Software: TListBox;
    P_Status: TPanel;
    L_Candidates: TListBox;
    B_Add: TBitBtn;
    B_Remove: TBitBtn;
    B_Info: TBitBtn;
    B_Up: TBitBtn;
    B_Down: TBitBtn;
    I_Check1: TImage;
    L_Status1: TLabel;
    I_Check2: TImage;
    L_Status2: TLabel;
    B_Start: TButton;
    CB_Drive: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure B_AddClick(Sender: TObject);
    procedure B_RemoveClick(Sender: TObject);
    procedure L_SoftwareKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure L_CandidatesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure B_UpClick(Sender: TObject);
    procedure L_CandidatesClick(Sender: TObject);
    procedure B_DownClick(Sender: TObject);
    procedure B_InfoClick(Sender: TObject);
    procedure L_SoftwareClick(Sender: TObject);
    procedure B_StartClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  F_Hitsugaya: TF_Hitsugaya;
  SwList:      array of THitSoft;

implementation

{$R *.dfm}

// PROCEDURES & FUNCTIONS
// -----------------------------------------------------------------------------

{empty}

// -----------------------------------------------------------------------------



// INITIAL SETTINGS
// -----------------------------------------------------------------------------
procedure TF_Hitsugaya.FormCreate(Sender: TObject);
var
    r:        LongWord;
    Drives:   array[0..128] of Char;
    uDrive:   array of Char;
    pDrive:   PChar;

    i:        Word;
    Res:      TSearchRec;
    Found:    Boolean;
begin
  SetLength(uDrive, 0);
  r := GetLogicalDriveStrings(SizeOf(Drives), Drives);
  if r <> 0 then
  begin
    if r > SizeOf(Drives) then
      raise Exception.Create(SysErrorMessage(ERROR_OUTOFMEMORY));
    pDrive := Drives;
    while pDrive^ <> #0 do
    begin
      SetLength(uDrive, Length(uDrive) + 1);
      uDrive[Length(uDrive) - 1]:= pDrive[0];
      inc(pDrive, 4);
    end;
  end;

  for r := 65 to 90 do
  begin
    i:= 0;
    Found:= False;
    while (i < Length(uDrive)) and not(Found) do
    begin
      if Chr(r) = uDrive[i] then
        Found:= True;
      inc(i);
    end;
    if not(Found) then
      F_Hitsugaya.CB_Drive.Items.Add(Chr(r) + ':');
  end;


  i:= 0;
  SetLength(SwList, 0);
  Found:= False;
  if not(FindFirst('config\*.bat', faAnyFile, Res) < 0) then
    while not Found do
    begin
      SetLength(SwList, Length(SwList) + 1);
      SwList[i]:= THitSoft.Create(Res.Name);

      L_Software.Items.Add(SwList[i].Name);

      Found:= FindNext(Res) <> 0;
      inc(i);
    end;
  FindClose(Res);

  E_Path.Text:= GetCurrentDir();

  if L_Software.Count > 0 then
  begin
    L_Software.ItemIndex:= 0;
    B_Add.Enabled:= True;
  end;
end;
// -----------------------------------------------------------------------------



// MOVE BETWEEN LISTBOX ELEMENTS
// -----------------------------------------------------------------------------
procedure TF_Hitsugaya.B_AddClick(Sender: TObject);
var i:      Word;
    found:  Bool;
begin
  i:= 0;
  found:= False;
  while not(found) and (i < L_Candidates.Count) do
  begin
    if L_Candidates.Items[i] = L_Software.Items[L_Software.ItemIndex] then
      found:= True;
    inc(i);
  end;

  if not(found) then
    L_Candidates.Items.Add(L_Software.Items[L_Software.ItemIndex]);

  // Sposto la selezione sul SW appena selezionato
  L_Candidates.ItemIndex:= L_Candidates.Count - 1;

  if L_Candidates.Count > 0 then
  begin
    B_Start.Enabled:= True;
    B_Remove.Enabled:= True;
  end;
  L_CandidatesClick(Sender);
end;

procedure TF_Hitsugaya.B_RemoveClick(Sender: TObject);
var tmp: Integer;
begin
  if (L_Candidates.ItemIndex > 0) or ((L_Candidates.ItemIndex = 0) and (L_Candidates.Count = 1)) then
    tmp:= L_Candidates.ItemIndex - 1
  else if ((L_Candidates.ItemIndex + 1) <= L_Candidates.Count) then
    tmp:= L_Candidates.ItemIndex + 1
  else
    tmp:= -1;

  L_Candidates.Items.Delete(L_Candidates.ItemIndex);

  // Sposto la selezione sul SW appena sopra
  L_Candidates.ItemIndex:= tmp;

  L_CandidatesClick(Sender);
end;
// -----------------------------------------------------------------------------



// MOVE CANDIDATES LISTBOX ELEMENTS UP & DOWN
// -----------------------------------------------------------------------------
procedure TF_Hitsugaya.B_UpClick(Sender: TObject);
var S: ShortString;
begin
  S:= L_Candidates.Items[L_Candidates.ItemIndex - 1];
  L_Candidates.Items[L_Candidates.ItemIndex - 1]:= L_Candidates.Items[L_Candidates.ItemIndex];
  L_Candidates.Items[L_Candidates.ItemIndex]:= S;

  L_Candidates.ItemIndex:= L_Candidates.ItemIndex - 1;
  L_CandidatesClick(Sender);
end;

procedure TF_Hitsugaya.B_DownClick(Sender: TObject);
var S: ShortString;
begin
  S:= L_Candidates.Items[L_Candidates.ItemIndex + 1];
  L_Candidates.Items[L_Candidates.ItemIndex + 1]:= L_Candidates.Items[L_Candidates.ItemIndex];
  L_Candidates.Items[L_Candidates.ItemIndex]:= S;

  L_Candidates.ItemIndex:= L_Candidates.ItemIndex + 1;
  L_CandidatesClick(Sender);
end;
// -----------------------------------------------------------------------------



procedure TF_Hitsugaya.B_InfoClick(Sender: TObject);
begin
  MessageDlg(SwList[L_Software.ItemIndex].Version, mtInformation, [mbOK], 0);
end;



// KEYBOARD CONTROLS SETTINGS
// -----------------------------------------------------------------------------
procedure TF_Hitsugaya.L_CandidatesClick(Sender: TObject);
begin
  if L_Candidates.ItemIndex = -1 then
  begin
    B_Start.Enabled:= False;
    B_Remove.Enabled:= False;
    B_Up.Enabled:= False;
    B_Down.Enabled:= False;
  end
  else if (L_Candidates.ItemIndex = 0) and (L_Candidates.Count = 1) Then
    begin
      B_Up.Enabled:= False;
      B_Up.Enabled:= False;
    end
  else if L_Candidates.ItemIndex = (L_Candidates.Count - 1) then
    begin
      B_Up.Enabled:= True;
      B_Down.Enabled:= False;
    end
  else if L_Candidates.ItemIndex = 0 then
    begin
      B_Up.Enabled:= False;
      B_Down.Enabled:= True;
    end
  else
    begin
      B_Up.Enabled:= True;
      B_Down.Enabled:= True;
    end;
end;

procedure TF_Hitsugaya.L_CandidatesKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = 8) and (L_Candidates.Count > 0) Then
    B_RemoveClick(Sender);
  L_CandidatesClick(Sender);
end;

procedure TF_Hitsugaya.L_SoftwareClick(Sender: TObject);
begin
  if SwList[L_Software.ItemIndex].Version = 'v' then
    B_Info.Enabled:= False
  else
    B_Info.Enabled:= True;
end;

procedure TF_Hitsugaya.L_SoftwareKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = 13) and (L_Candidates.Count > 0) Then
    B_AddClick(Sender);
  L_SoftwareClick(Sender);
  L_CandidatesClick(Sender);
end;
// -----------------------------------------------------------------------------



procedure TF_Hitsugaya.B_StartClick(Sender: TObject);
var
  i,j:            Word;
  Found:          Bool;
  Element:        ShortString;
  HitInstallFile: TextFile;
begin
  //1st Step -----
  I_Check1.Visible:= True;
  L_Status1.Visible:= True;
  L_Status1.Font.Style:= L_Status1.Font.Style + [fsBold];

  AssignFile(HitInstallFile, 'config\install\install.bat');
  Rewrite(HitInstallFile);
  Writeln(HitInstallFile, '@echo off');
  Writeln(HitInstallFile, 'cls');
  Writeln(HitInstallFile, 'echo Hitsugaya installation Batch');
  Writeln(HitInstallFile, 'echo ----------');

  if CB_Mapping.Checked then
  begin
    Writeln(HitInstallFile, 'echo Mappatura di ' + E_Path.Text + ' in ' + CB_Drive.Items[CB_Drive.ItemIndex] + ' ...');
    Writeln(HitInstallFile, 'net use ' + CB_Drive.Items[CB_Drive.ItemIndex] + ' ' + E_Path.Text + ' /PERSISTENT:NO');
    Writeln(HitInstallFile, 'echo ----------');
  end;

  for j:= 0 to (L_Candidates.Count - 1) do
  begin
    i:= 0;
    Found:= False;
    while (i < L_Software.Count) and not(Found) do
    begin
      if L_Software.Items[i] = L_Candidates.Items[j] then
        Found:= True;
      inc(i);
    end;

    if Found then
    begin
      Writeln(HitInstallFile, 'echo Installazione ' + IntToStr(j + 1) + ' di ' + IntToStr(L_Candidates.Count) + ' in corso...');
      Writeln(HitInstallFile, 'echo Installazione di ' + SwList[i - 1].Name + '...');
      Writeln(HitInstallFile, 'start /wait config\' + SwList[i - 1].Params);
      Writeln(HitInstallFile, 'echo ----------');
    end;
  end;
  Writeln(HitInstallFile, 'pause');

  CloseFile(HitInstallFile);
  I_Check1.Picture.LoadFromFile('img\check.png');
  L_Status1.Caption:= L_Status1.Caption + ' OK';
  L_Status1.Font.Style:= L_Status1.Font.Style - [fsBold];
  //----------

  //2nd Step -----
  I_Check2.Visible:= True;
  L_Status2.Visible:= True;
  L_Status2.Font.Style:= L_Status2.Font.Style + [fsBold];

  ShellExecute(Handle, 'open', 'config\install\install.bat', nil, nil, SW_SHOWNORMAL);

  I_Check2.Picture.LoadFromFile('img\check.png');
  L_Status2.Caption:= L_Status2.Caption + ' OK';
  L_Status2.Font.Style:= L_Status2.Font.Style - [fsBold];
  //----------

  Sleep(3000);
  F_Hitsugaya.Close;
end;



end.