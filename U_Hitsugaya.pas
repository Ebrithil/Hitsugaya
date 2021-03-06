unit U_Hitsugaya;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, ShellApi, StrUtils,
  ImgList, XMLDoc, XMLIntf, jpeg, xmldom, msxmldom, CheckLst,
  U_Classes, U_ExtProcFunc;

type
    TF_Hitsugaya = class(TForm)
    P_Spacer: TPanel;
    I_Logo: TImage;
    P_Mapping: TPanel;
    E_Path: TEdit;
    CB_Mapping: TCheckBox;
    LB_Software: TListBox;
    P_Status: TPanel;
    LB_Candidates: TListBox;
    B_Add: TBitBtn;
    B_Remove: TBitBtn;
    B_Info: TBitBtn;
    B_Up: TBitBtn;
    B_Down: TBitBtn;
    B_Start: TButton;
    CB_Drive: TComboBox;
    IL_Hitsugaya: TImageList;
    CB_Category: TComboBox;
    XMLConfig: TXMLDocument;
    B_Update: TBitBtn;
    CLB_Status: TCheckListBox;
    OD_Update: TOpenDialog;
    P_WSUS: TPanel;
    E_Path_WSUS: TEdit;
    CB_Mapping_WSUS: TCheckBox;
    CB_Drive_WSUS: TComboBox;
    CB_Reboot: TCheckBox;
    L_Bits: TLabel;
    procedure B_AddClick(Sender: TObject);
    procedure B_RemoveClick(Sender: TObject);
    procedure B_UpClick(Sender: TObject);
    procedure LB_CandidatesClick(Sender: TObject);
    procedure B_DownClick(Sender: TObject);
    procedure B_InfoClick(Sender: TObject);
    procedure B_StartClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CB_CategoryChange(Sender: TObject);
    procedure CB_CategoryKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure B_UpdateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    SwList: U_ExtProcFunc.SWList;
  end;

const
  SW_PATH = 'config\';

var
  F_Hitsugaya: TF_Hitsugaya;

implementation

uses U_Loading;

{$R *.dfm}

// PROCEDURES & FUNCTIONS
// -----------------------------------------------------------------------------
procedure SaveCurrentConfig(const FileName: String);
var
    i:                  Integer;
    Config:             TXmlDocument;
    MainNode,           // Hitsugaya
      MappingNode,      // Mapping
        PathNode,       // Executing Path
      SoftwareNode,
        CandidatesNode: IXMLNode;
begin
  // Save current config into XML file
  Config:= TXMLDocument.Create(nil);
  Config.Options := [doNodeAutoIndent];
  Config.Active:= True;

  MainNode:= Config.AddChild('program');
    MappingNode:= MainNode.AddChild('mapping');

    if F_Hitsugaya.CB_Mapping.Checked then
      MappingNode.Attributes['active']:= true
    else
      MappingNode.Attributes['active']:= false;

    MappingNode.Attributes['drive']:= F_Hitsugaya.CB_Drive.Items[F_Hitsugaya.CB_Drive.ItemIndex];
      PathNode:= MappingNode.AddChild('path');
      PathNode.Text:= F_Hitsugaya.E_Path.Text;

    SoftwareNode:= MainNode.AddChild('software');
    for i := 0 to F_Hitsugaya.LB_Candidates.Items.Count - 1 do
    begin
        CandidatesNode:= SoftwareNode.AddChild('candidate');
        CandidatesNode.Text:= F_Hitsugaya.LB_Candidates.Items[i];
    end;

  Config.SaveToFile(FileName);
end;

procedure LoadConfig(const FileName: String);
var
  i,
  index:      Integer;
  Mapping,
  Software:   IXMLNode;
begin
  F_Hitsugaya.XMLConfig.FileName:= GetCurrentDir() + '\' + FileName;
  F_Hitsugaya.XMLConfig.Active:= True;

  // Mapping
  Mapping:= F_Hitsugaya.XMLConfig.DocumentElement.ChildNodes.FindNode('mapping');
  F_Hitsugaya.E_Path.Text:= Mapping.ChildNodes['path'].Text;

  if F_Hitsugaya.CB_Drive.Items.IndexOf(Mapping.Attributes['drive']) = -1 then
    F_Hitsugaya.CB_Drive.ItemIndex:= F_Hitsugaya.CB_Drive.Items.Count - 1
  else
    F_Hitsugaya.CB_Drive.Text:= Mapping.Attributes['drive'];

  if Mapping.Attributes['active'] = 'true' then
    F_Hitsugaya.CB_Mapping.Checked:= true
  else
    F_Hitsugaya.CB_Mapping.Checked:= false;
  // ----------

  // Candidates
  if F_Hitsugaya.CB_Category.Items.Count > 0 then
  begin
    F_Hitsugaya.CB_Category.ItemIndex:= 0;
    F_Hitsugaya.CB_CategoryChange(F_Hitsugaya.CB_Category);
  end;

  Software:= F_Hitsugaya.XMLConfig.DocumentElement.ChildNodes.FindNode('software');
  for i:= 0 to Software.ChildNodes.Count - 1 do
  begin
    index:= F_Hitsugaya.LB_Software.Items.IndexOf(Software.ChildNodes[i].Text);
    if index <> -1 then
    begin
       F_Hitsugaya.LB_Software.ItemIndex:= index;
       F_Hitsugaya.B_Add.Click;
    end;
  end;
  // ----------
end;
// -----------------------------------------------------------------------------



// MOVE BETWEEN LISTBOX ELEMENTS
// -----------------------------------------------------------------------------
procedure TF_Hitsugaya.B_AddClick(Sender: TObject);
var i:      Word;
begin
  if LB_Software.ItemIndex = -1 then
    Exit;

  // Impedisco la perdita della selezione
  if (LB_Software.ItemIndex + 1) >= (LB_Software.Count - 1) then
    i:= LB_Software.ItemIndex + 1
  else
    i:= LB_Software.ItemIndex - 1;

  LB_Candidates.Items.Add(LB_Software.Items[LB_Software.ItemIndex]);
  LB_Software.Items.Delete(LB_Software.ItemIndex);

  LB_Software.ItemIndex:= i;
  if (LB_Software.ItemIndex = -1) and (LB_Software.Items.Count > 0) then
    LB_Software.ItemIndex:= 0;

  // Sposto la selezione sul SW appena selezionato
  LB_Candidates.ItemIndex:= LB_Candidates.Count - 1;

  if LB_Candidates.Count > 0 then
  begin
    B_Start.Enabled:= True;
    B_Remove.Enabled:= True;
  end;
  LB_CandidatesClick(Sender);
end;

procedure TF_Hitsugaya.B_RemoveClick(Sender: TObject);
var i, tmp: Integer;
begin
  if LB_Candidates.ItemIndex = -1 then
    Exit;

  if (LB_Candidates.ItemIndex > 0) or ((LB_Candidates.ItemIndex = 0) and (LB_Candidates.Count = 1)) then
    tmp:= LB_Candidates.ItemIndex - 1
  else if ((LB_Candidates.ItemIndex + 1) <= LB_Candidates.Count) then
    tmp:= LB_Candidates.ItemIndex + 1
  else
    tmp:= -1;

  // Impedisco la perdita della selezione
  i:= LB_Candidates.ItemIndex - 1;

  LB_Software.Items.Add(LB_Candidates.Items[LB_Candidates.ItemIndex]);
  LB_Software.ItemIndex:= LB_Software.Items.IndexOf(LB_Candidates.Items[LB_Candidates.ItemIndex]);

  LB_Candidates.Items.Delete(LB_Candidates.ItemIndex);

  // Impedisco la perdita della selezione
  LB_Candidates.ItemIndex:= i;
  if (LB_Candidates.ItemIndex = -1) and (LB_Candidates.Items.Count > 0) then
    LB_Candidates.ItemIndex:= 0;

  // Sposto la selezione sul SW appena sopra
  LB_Candidates.ItemIndex:= tmp;

  LB_CandidatesClick(Sender);
end;
// -----------------------------------------------------------------------------



// SOFTWARE OPERATIONS
// -----------------------------------------------------------------------------
procedure TF_Hitsugaya.B_InfoClick(Sender: TObject);
begin
  MessageDlg(
    SwList[HitSoftFind(LB_Software.Items[LB_Software.ItemIndex], SwList)].Name
    + #13#10 +
    'v' + SwList[HitSoftFind(LB_Software.Items[LB_Software.ItemIndex], SwList)].Version,
    mtInformation, [mbOK], 0
    );
end;

procedure TF_Hitsugaya.B_UpdateClick(Sender: TObject);
var
  i:            Word;
  AutoCheck:    Boolean;
  sFile,
  sComm:        TStringList;
  bFile:        TextFile;
  Row,
  FilePath,
  NewFileVer,
  OldFileVer,
  OldFileName,
  NewFileName:  String;
begin
  // Security check
  if LB_Software.ItemIndex = -1 then
    Exit;

  // Update capability check
  if Length(SwList[HitSoftFind(LB_Software.Items[LB_Software.ItemIndex], SwList)].Commands) > 1 then
    begin
      MessageDlg('Impossibile aggiornare file batch con pi� di un comando!', mtError, [mbOK], 0);
      Exit;
    end;

  // Take old file path
  AssignFile(bFile, E_Path.Text + '\' + SW_PATH + SwList[HitSoftFind(LB_Software.Items[LB_Software.ItemIndex], SwList)].fName);
  Reset(bFile);

  FilePath:= '';
  while not(EoF(bFile)) and (FilePath = '') do
  begin
    Readln(bFile, Row);
    sComm:= Split(Trim(Row), ' ');
    for i:= 0 to sComm.Count - 1 do
      if FileExists(E_Path.Text + '\' + SW_PATH + sComm[i]) then
      begin
        FilePath:= E_Path.Text + '\' + SW_PATH + sComm[i];
        Break;
      end;
    sComm.Free;
  end;
  CloseFile(bFile);

  OldFileName:= RightStr(FilePath, Length(FilePath) - LastDelimiter('\', FilePath));
  FilePath:= LeftStr(FilePath, LastDelimiter('\', FilePath));

  // Take new file path
  OD_Update.Execute();
  if OD_Update.FileName = '' then
    Exit;

  NewFileName:= RightStr(OD_Update.FileName, Length(OD_Update.FileName) - LastDelimiter('\', OD_Update.FileName));
  // Replace all " " with "_"
  NewFileName:= StringReplace(NewFileName, ' ', '_', [rfReplaceAll]);

  // Ask for version
  AutoCheck:= False;
  OldFileVer:= SwList[HitSoftFind(LB_Software.Items[LB_Software.ItemIndex], SwList)].Version;
  NewFileVer:= InputBox('Richiesta Versione', 'Digitare la versione del file:' + #13#10 + '(lasciare vuoto per autorilevamento)', '' );
  if NewFileVer = '' then
  begin
    NewFileVer:= GetFileVer(OD_Update.FileName);
    AutoCheck:= True;
  end;

  // Operation confirmation
  if MessageDlg(
    'Sostituire il file' +
    #13#10 +
    #13#10 +
    OldFileName + ' (v' + OldFileVer + ')' +
    #13#10 +
    #13#10 +
    'con questo file:' +
    #13#10 +
    #13#10 +
    NewFileName + ' (v' + NewFileVer + ') ?',
    mtConfirmation, mbYesNo, 0, mbYes
    ) = mrYes then
      begin
        // Replace command line in batch file
        Reset(bFile);
        sFile:= TStringList.Create;
        while not(EoF(bFile)) do
        begin
          Readln(bFile, Row);
          sFile.Add(Trim(Row));
        end;
        CloseFile(bFile);

        Rewrite(bFile);
        for i := 0 to sFile.Count - 1 do
        begin
          if i = 1 then
            if AutoCheck then
              sFile[i]:= '::'
            else
              sFile[i]:= '::' + NewFileVer
          else
            sFile[i]:= StringReplace(sFile[i], OldFileName, NewFileName,[rfReplaceAll]);

          if i < (sFile.Count - 1) then
            Writeln(bFile, sFile[i])
          else
            Write(bFile, sFile[i]);
        end;
        CloseFile(bFile);

        sFile.Free;

        CopyFile(pChar(OD_Update.FileName), pChar(FilePath + NewFileName), True);
        if NewFileName <> OldFileName then
          DeleteFile(FilePath + OldFileName);

        // Rebuild software list
        SwList:= BuildSoftwareList(LB_Software);
        // Rebuild available categories list
        BuildCategoryList(SwList, CB_Category);

        MessageDlg('Aggiornamento completato', mtInformation, [mbOK], 0);
      end;
end;
// -----------------------------------------------------------------------------



// MOVE CANDIDATES LISTBOX ELEMENTS UP & DOWN
// -----------------------------------------------------------------------------
procedure TF_Hitsugaya.B_UpClick(Sender: TObject);
var S: String;
begin
  S:= LB_Candidates.Items[LB_Candidates.ItemIndex - 1];
  LB_Candidates.Items[LB_Candidates.ItemIndex - 1]:= LB_Candidates.Items[LB_Candidates.ItemIndex];
  LB_Candidates.Items[LB_Candidates.ItemIndex]:= S;

  LB_Candidates.ItemIndex:= LB_Candidates.ItemIndex - 1;
  LB_CandidatesClick(Sender);
end;

procedure TF_Hitsugaya.B_DownClick(Sender: TObject);
var S: String;
begin
  S:= LB_Candidates.Items[LB_Candidates.ItemIndex + 1];
  LB_Candidates.Items[LB_Candidates.ItemIndex + 1]:= LB_Candidates.Items[LB_Candidates.ItemIndex];
  LB_Candidates.Items[LB_Candidates.ItemIndex]:= S;

  LB_Candidates.ItemIndex:= LB_Candidates.ItemIndex + 1;
  LB_CandidatesClick(Sender);
end;
// -----------------------------------------------------------------------------



// MOUSE & KEYBOARD CONTROLS SETTINGS
// -----------------------------------------------------------------------------
procedure TF_Hitsugaya.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    8:   if LB_Candidates.ItemIndex > -1  then B_RemoveClick(Sender);
    13:  if LB_Software.ItemIndex > -1    then B_AddClick(Sender);
    112: ShowMessage('F1: Visualizza questo Help' + #13#10 + #13#10 +
                     'F3: Salva in XML la configurazione per Aziende' + #13#10 +
                     'F4: Salva in XML la configurazione per Privati' + #13#10 +
                     'F7: Carica in XML la configurazione per Aziende' + #13#10 +
                     'F8: Carica in XML la configurazione per Privati' + #13#10 +
                     'F10: Compila ed Esegue i comandi selezionati');
    114: begin
            SaveCurrentConfig('business.xml');
            MessageDlg('Configurazione per Aziende salvata', mtInformation, [mbOK], 0);
         end;
    115: begin
            SaveCurrentConfig('home.xml');
            MessageDlg('Configurazione per Privati salvata', mtInformation, [mbOK], 0);
         end;
    118: begin
            LoadConfig('business.xml');
            MessageDlg('Configurazione per Aziende caricata', mtInformation, [mbOK], 0);
         end;
    119: begin
            LoadConfig('home.xml');
            MessageDlg('Configurazione per Privati caricata', mtInformation, [mbOK], 0);
         end;
    121: B_StartClick(Sender);
  end;

  LB_CandidatesClick(Sender);
end;

procedure TF_Hitsugaya.FormShow(Sender: TObject);
begin
  F_Loading.Close;
end;

procedure TF_Hitsugaya.LB_CandidatesClick(Sender: TObject);
begin
  if LB_Candidates.ItemIndex = -1 then
  begin
    B_Start.Enabled:= False;
    B_Remove.Enabled:= False;
    B_Up.Enabled:= False;
    B_Down.Enabled:= False;
  end
  else if (LB_Candidates.ItemIndex = 0) and (LB_Candidates.Count = 1) Then
    begin
      B_Up.Enabled:= False;
      B_Up.Enabled:= False;
    end
  else if LB_Candidates.ItemIndex = (LB_Candidates.Count - 1) then
    begin
      B_Up.Enabled:= True;
      B_Down.Enabled:= False;
    end
  else if LB_Candidates.ItemIndex = 0 then
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

procedure TF_Hitsugaya.CB_CategoryChange(Sender: TObject);
var i: Integer;
begin
  LB_Software.Items.Clear;
  for i := 0 to Length(SwList) - 1 do
    if (SwList[i].Category = CB_Category.Items[CB_Category.ItemIndex])
        or
       (CB_Category.ItemIndex = 0)
    then
      LB_Software.Items.Add(SwList[i].Name);
end;

// Disallow user to manually modify current category
procedure TF_Hitsugaya.CB_CategoryKeyPress(Sender: TObject; var Key: Char);
begin
  Key:= #0;
end;

// -----------------------------------------------------------------------------



// FINAL BATCH CREATION
// -----------------------------------------------------------------------------
procedure TF_Hitsugaya.B_StartClick(Sender: TObject);
var
  i,j,k,y:        Integer;
  HitInstallFile: TextFile;
  StrList:        TStringList;
begin
  // 1st Step -----
  CLB_Status.Items.Add('Creating Batch File...');

  // Precautionary cleaning
  if FileExists(GetEnvironmentVariable('TEMP') + '\hitsugaya.bat') then
    DeleteFile(GetEnvironmentVariable('TEMP') + '\hitsugaya.bat');

  AssignFile(HitInstallFile, GetEnvironmentVariable('TEMP') + '\hitsugaya.bat');
  Rewrite(HitInstallFile);

  Writeln(HitInstallFile, '@echo off');
  Writeln(HitInstallFile, 'color 0A');
  Writeln(HitInstallFile, 'cls');
  Writeln(HitInstallFile, 'echo Hitsugaya installation Batch');
  Writeln(HitInstallFile, 'echo ----------');

  // Map remote paths
  if CB_Mapping.Checked then
  begin
    Writeln(HitInstallFile, 'echo Mappatura di ' + E_Path.Text + ' in ' + CB_Drive.Items[CB_Drive.ItemIndex] + ' ...');
    Writeln(HitInstallFile, 'net use ' + CB_Drive.Items[CB_Drive.ItemIndex] + ' ' + E_Path.Text + ' /PERSISTENT:NO');
    Writeln(HitInstallFile, 'echo ----------');
  end;
  if CB_Mapping_WSUS.Checked then
  begin
    Writeln(HitInstallFile, 'echo Mappatura di ' + E_Path_WSUS.Text + ' in ' + CB_Drive_WSUS.Items[CB_Drive_WSUS.ItemIndex] + ' ...');
    Writeln(HitInstallFile, 'net use ' + CB_Drive_WSUS.Items[CB_Drive_WSUS.ItemIndex] + ' ' + E_Path_WSUS.Text + ' /PERSISTENT:NO');
    Writeln(HitInstallFile, 'echo ----------');
  end;

  // Remove *.exe authorization prompt
  Writeln(HitInstallFile, 'echo Abilitazione Esecuzione file exe...');
  if CB_Mapping.Checked then
    Writeln(HitInstallFile, 'REG IMPORT ' + CB_Drive.Items[CB_Drive.ItemIndex] + '\tools\EnableRemoteExe.reg')
  else
    Writeln(HitInstallFile, 'REG IMPORT ' + E_Path.Text + '\tools\EnableRemoteExe.reg');
  Writeln(HitInstallFile, 'gpupdate /force');
  Writeln(HitInstallFile, 'echo ----------');

  // Create installation list
  for j:= 0 to (LB_Candidates.Count - 1) do
  begin
    i:= HitSoftFind(LB_Candidates.Items[j], SwList);

    if i <> -1 then
    begin
      Writeln(HitInstallFile, 'echo Installazione ' + IntToStr(j + 1) + ' di ' + IntToStr(LB_Candidates.Count) + ' in corso...');
      Writeln(HitInstallFile, 'echo Installazione di ' + SwList[i].Name + '...');
      for k := 0 to Length(SwList[i].Commands) - 1 do
      begin
        Writeln(HitInstallFile, 'echo   Esecuzione comando ' + IntToStr(k + 1) + ' di ' + IntToStr(Length(SwList[i].Commands)) + '...');
        Write(HitInstallFile, 'start /wait');

        StrList:= Split(SwList[i].Commands[k], ' ');
        for y := 0 to StrList.Count - 1 do
          if FileExists(SW_PATH + StrList[y]) then
            if CB_Mapping.Checked then
              Write(HitInstallFile, ' ' + CB_Drive.Items[CB_Drive.ItemIndex] + '\' + SW_PATH + StrList[y])
            else
              Write(HitInstallFile, ' ' + SW_PATH + StrList[y])
          else
            Write(HitInstallFile, ' ' + StrList[y]);
        Writeln(HitInstallFile, '');
      end;

      Writeln(HitInstallFile, 'echo ----------');
    end;
  end;

  // If selected, launch WSUS offline
  if CB_Mapping_WSUS.Checked then
  begin
    Writeln(HitInstallFile, 'echo Installazione degli aggiornamenti WSUS...');
    if CB_Reboot.Checked then
      Writeln(HitInstallFile, 'start ' + CB_Drive_WSUS.Items[CB_Drive_WSUS.ItemIndex] + '\cmd\DoUpdate.cmd /autoreboot')
    else
      Writeln(HitInstallFile, 'start ' + CB_Drive_WSUS.Items[CB_Drive_WSUS.ItemIndex] + '\cmd\DoUpdate.cmd');
    Writeln(HitInstallFile, 'echo ----------');
  end;

  // Re-enable remote exe authorization prompt
  Writeln(HitInstallFile, 'echo Ripristino protezioni file exe...');
  Writeln(HitInstallFile, 'REG DELETE HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Associations /f');
  Writeln(HitInstallFile, 'gpupdate /force');
  Writeln(HitInstallFile, 'echo ----------');

  // Modify windows registry to optimize startup/shutdown
  Writeln(HitInstallFile, 'echo Ottimizzazione registro di sistema...');
  if CB_Mapping.Checked then
    Writeln(HitInstallFile, 'REG IMPORT ' + CB_Drive.Items[CB_Drive.ItemIndex] + '\tools\WindowsOptimize.reg')
  else
    Writeln(HitInstallFile, 'REG IMPORT ' + E_Path.Text + '\tools\WindowsOptimize.reg');
  Writeln(HitInstallFile, 'echo ----------');

  if CB_Reboot.Checked and not(CB_Mapping_WSUS.Checked) then
    Writeln(HitInstallFile, 'shutdown -r -c "Riavvio programmato da IBS Hitsugaya"');

  Writeln(HitInstallFile, 'pause');

  CloseFile(HitInstallFile);

  CLB_Status.Checked[CLB_Status.Count - 1]:= True;
  //----------

  // 2nd Step -----
  CLB_Status.Items.Add('Executing Batch File...');

  // Run installation script
  ShellExecute(Handle, 'open', PChar(GetEnvironmentVariable('TEMP') + '\hitsugaya.bat'), nil, nil, SW_SHOWNORMAL);

  CLB_Status.Checked[CLB_Status.Count - 1]:= True;
  //----------

  Sleep(3000);
  F_Hitsugaya.Close;
end;
// -----------------------------------------------------------------------------



// FINAL OPERATIONS
// -----------------------------------------------------------------------------
procedure TF_Hitsugaya.FormClose(Sender: TObject; var Action: TCloseAction);
var vFile: TextFile;
begin
  if FileExists('P_Hitsugaya.exe') then
  begin
    AssignFile(vFile, 'version');
    Rewrite(vFile);
    Write(vFile, GetFileVer('P_Hitsugaya.exe'));
    CloseFile(vFile);
  end;
end;

procedure TF_Hitsugaya.FormCreate(Sender: TObject);
begin
end;

// -----------------------------------------------------------------------------

end.
