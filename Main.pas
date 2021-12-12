//This software was developed by MsC. Gabriel Arantes Tiraboschi

//Date : August 2018

//Name of the program : Faces

//Description : This program was developed to present pictures of faces in a scale using the
//psychophysical StairCase method. This program used a double stair procedure. Each stair is
//presented randomly to the participant. The results are recorded in a *.txt file at the end
//of the experiment

//Revision History
//v 1.1. - 14/08/2018 - The subtitle at the main form was corrected to correctly associate
//the number of the the stimuli and its morphing percentege. Also the LOWER and the
//HIGHEST stimuli were set to 3 and 17 respectively

unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.ImageList, Vcl.ImgList, Vcl.Menus, Instrucoes, credits, TypInfo;

type
  TemotionsEnu = (Alegria, Medo, Nojo, Raiva, Surpresa, Tristeza); // All the emotions starting with zero
  TformMain = class(TForm)  //The main form
    participantName: TEdit;
    participantNumber: TEdit;
    participantSex: TComboBox;
    labelName: TLabel;
    labelNumeroPart: TLabel;
    labelSex: TLabel;
    methodPanel: TPanel;
    startingA: TLabel;
    labelPanel: TLabel;
    labelStopRule: TLabel;
    stopRuleEdit: TEdit;
    startButton: TButton;
    faceImage: TImage;
    presentationTime: TTimer;
    cross: TLabel;
    descanso: TLabel;
    startingB: TLabel;
    startingStimulusA: TComboBox;
    startingStimulusB: TComboBox;
    StimuliTimer: TTimer;
    tempoLabel: TLabel;
    stimuliTime: TEdit;
    responseLabel: TLabel;
    topMenu: TMainMenu;
    aplicativo: TMenuItem;
    instrucao: TMenuItem;
    sobre: TMenuItem;
    fechar: TMenuItem;
    separator: TMenuItem;
    emotionsLb: TLabel;
    emotionsBox: TComboBox;
    Hint: TLabel;
    credit: TLabel;


    {procedures declarations}
    procedure FormCreate(Sender: TObject); //when the form is created
    procedure startButtonClick(Sender: TObject); //when the experimenter clicks on the start button
    procedure FormClose(Sender: TObject; var Action: TCloseAction); //when the form is closed
    procedure presentationTimeTimer(Sender: TObject); //Timer to present the fixation cross and stimuli
    procedure StairCaseInterval; //Method to start and loop the staircase method
    procedure FormKeyPress(Sender: TObject; var Key: Char); //a keylistener
    procedure saveResults; //save the results to a txt file
    procedure StimuliTimerTimer(Sender: TObject);
    procedure fecharClick(Sender: TObject);
    procedure instrucaoClick(Sender: TObject);
    procedure sobreClick(Sender: TObject);
 //Timer to hide the stimuli and present the question



  private
    { Private declarations }
  public
    { Public declarations }



  end;

const
  HIGHIEST_STIMULUS = 17; //the highest simulus permited
  LOWEST_STIMULUS = 3; //the lowest stimulus allowed
  UP = 1; //How much to increase after response
  DOWN = 1; //How much to decreaseafter response
  NUMBER_OF_EMOTIONS = 6; //The total number of emotions
  EXCLUDED_TRIALS = 2; //How many trials to exclude of the mean count
  PERCENT_MULTIPLYER = 5;

var
formMain: TformMain;
emotionEnu : TemotionsEnu;

implementation

{$R *.dfm}

var
  {experiment initial parameters}
  startNumA : Integer; //the starting stiumlus
  startNumB : Integer; //the starting stiumlus
	stopRule : Integer; //the number of reversals to stop the experiment
  stimulusTime : Integer; //time in ms that the stimulus is going to be visible
  reversal : Integer; //number of reversals
  emotion : String; //The first letter of the emotion


  {participants' variables}
  pName : string; //participant's name
	pNumber : string; //participant's number
  sex : string; //participant's sex
  startTime : string;  //time and date that the participant started the experiment
  finishTime : string; //time and date that the participant finished the experiment
  responsesBlockA : array of string; //array of responses in the A block
  responsesBlockB : array of string;//array of responses in the B block

  {stairCase method variables}
  //Boolean variables to check each part of the trial
  experiment : Boolean; //experiment mode
  interval : Boolean; //interval mode
  //Changing variables
  currentStimulus1 : Integer; // stimuli index
  currentStimulus2 : Integer; // stimuli index
  currentBlock : Integer; //the current block A or B
  lastResponseA : Char; //the last response from participant
  lastResponseB : Char; //the last response from participant
  //counts the number of trails
  trialsA : Integer; //total number of trials so far
  trialsB : Integer; //total number of trials so far
  //takes note of the presented stimuli
  stimuliSequenceA : array of string; //array of stimuli presented in A block
  stimuliSequenceB : array of string; //array of stimuli presented in B block
  //record the stimulus intensity when a reversal took place
  reversalIntensityA : array of Integer; //array of stimulus intensities when a reversal took place
  reversalIntensityB : array of Integer; //array of stimulus intensities when a reversal took place

  {windows taskbar variables}
  Form1: TFormMain;
  hTaskBar: HWND;

  //forward declarations
  function increaseOrDecrease (Key: Char; index : Integer ) : Integer; forward;
  procedure  responseRecord (Key : Char); forward;

{At the moment that the main form is created}
procedure  TformMain.FormCreate(Sender: TObject);
var
i : Integer;

  begin
     {Creates the options on the sex combo box}
     participantSex.Items.Add('Feminino');
     participantSex.Items.Add('Masculino');
     {Creates the option on the emotions combo box}
     emotionsBox.DropDownCount := NUMBER_OF_EMOTIONS;
     for emotionEnu := Alegria to Tristeza do //using the emotionEnu enumerated type
     begin
      emotionsBox.Items.Add(GetEnumName(TypeInfo (TemotionsEnu), Integer(emotionEnu))); //Gets the name(string) by its integer
     end;
     emotionsBox.ItemIndex := 0;
     {Creates the option on the starting stimuli combo box}
     for i := LOWEST_STIMULUS to HIGHIEST_STIMULUS do
     begin
      startingStimulusA.Items.Add(IntToStr(i));
      startingStimulusB.Items.Add(IntToStr(i));
     end;
     startingStimulusA.ItemIndex := 0; //Sets the default option to the lowest stimuli possible
     startingStimulusB.ItemIndex := HIGHIEST_STIMULUS - LOWEST_STIMULUS; //Sets the default option to the highest stimuli possible
     startingStimulusA.DropDownCount := HIGHIEST_STIMULUS; //Sets the number of items displayed at once
     startingStimulusB.DropDownCount := HIGHIEST_STIMULUS; //Sets the number of items displayed at once
  end;

{When the experimenter clicks to start the experiment}
procedure TformMain.startButtonClick(Sender: TObject);
var
emotiName : string;

begin
  {Stores the inputed data}
    startNumA := strtoint (startingStimulusA.Text); //the starting stimuli of the first staircase procedure
    startNumB := strtoint (startingStimulusB.Text);  //the starting stimuli of the second staircase procedure
    stopRule := strtoint (stopRuleEdit.Text); //how many reversals to end the experiment
    stimulusTime := StrToInt(stimuliTime.Text); //how long the stimuli is going to be presented
    emotion := emotionsBox.Text; //which emotion is going to be presented
    //participants' variables
    pNumber := participantNumber.Text;
    pName := participantName.Text;
    sex := participantSex.Text;
    startTime := DateTimeToStr (Now);


  {Destroys all labels and edit boxes}
    participantName.Free;
    participantNumber.Free;
    participantSex.Free;
    labelName.Free;
    labelNumeroPart.Free;
    labelSex.Free;
    emotionsBox.Free;
    emotionsLb.Free;
    credit.Free;
    startingA.Free;
    startingB.Free;
    labelPanel.Free;
    startingStimulusA.Free;
    startingStimulusB.Free;
    labelStopRule.Free;
    stopRuleEdit.Free;
    tempoLabel.Free;
    stimuliTime.Free;
    startButton.Free;
    methodPanel.Free;

   {changes the window to full screen and without border}
    BorderStyle := bsNone; //no window border
    formMain.BringToFront;
    WindowState := wsMaximized; //maximize the window
    formMain.Color := clBlack;  //Changes the background color to black
    formMain.DoubleBuffered := true; //Many times when images are changed, the display flickers. This will stop it.
    ShowCursor(False); //hides the  ouse cursor
    topMenu.Free; //destroy the top menu
    //These below hide the windows taskbar
    hTaskBar := FindWindow('Shell_TrayWnd', nil);
    ShowWindow(hTaskBar, SW_HIDE);

    {Sets experiment variables}
    currentStimulus1 := startNumA;
    currentStimulus2 := startNumB;
    StimuliTimer.Interval := stimulusTime; //how long the stimuli is going to be presented
    reversal := 0; //total number of reversals of the entire experiment
    trialsA := 0; //total number of trails of the first staircase procedure
    trialsB := 0; //total number of trails of the first staircase procedure
    {starts the staircase method}
    emotionEnu := TemotionsEnu (GetEnumValue(TypeInfo(TemotionsEnu), emotion));
    case emotionEnu of
      Alegria : emotiName := 'alegre';
      Medo : emotiName := 'com medo';
      Nojo : emotiName := 'com nojo';
      Raiva : emotiName := 'com raiva';
      Surpresa : emotiName := 'surpresa';
      Tristeza : emotiName := 'triste';
    end;
    //sets the response screen label text
    responseLabel.Caption := 'A face está ' + emotiName + '?' +
    #13#10 + '1 - Para Neutro' +
    #13#10 + '2 - Para ' + emotion;
    StairCaseInterval; //starts by the interval part of the trial
end;

{the stair case interval in which the participant has to press the spacebar}
procedure TformMain.StairCaseInterval;

  begin
    {randomly chooses which of the two staircase is going to be}
    Randomize;
    currentBlock := Random (2)+1; //+1 because it could be 0 or 1
    {adds to the total number of trials}
    if (currentBlock = 1) then Inc (trialsA);
    if (currentBlock = 2) then Inc (trialsB);
    {records in the stimuliSequence array the stimuli presented in each trial}
    if (currentBlock = 1) then
      begin
        SetLength(stimuliSequenceA, trialsA);
        stimuliSequenceA [trialsA-1] := IntToStr(currentStimulus1);
      end;
    if (currentBlock = 2) then
      begin
        SetLength(stimuliSequenceB, trialsB);
        stimuliSequenceB [trialsB-1] := IntToStr(currentStimulus2);
      end;
    {presents the interval screen to the participant and sets the interval mode to true}
    interval := true;
    descanso.Visible := true;
  end;

{When the participant press a key - participants' response}
procedure TformMain.FormKeyPress(Sender: TObject; var Key: Char);
begin

   //****** STIMULI PRESENTATION ******
    {if the participant press the spacebar during the interval part of the trial}
    if (Key = #32 {Spacebar}) and (interval = true) then
    begin
      interval := false; //turns off interval mode
      descanso.Visible := false; //hides the message to press spacebar
      cross.Visible := true;  //present the fixation cross
      {In 500ms hides the fixation cross, present the stimuli for a ginve time,
      asks the participant for a response, and enable experiment mode:}
      presentationTime.Enabled := true;
    end;

    //********** RESPONSE ***************
    {if participant press the keys 1 or 2 during the experiment mode (when they are asked to respond)}
    if (Key = #49) or (Key = #50) then
    begin
      if (experiment = true)then //during the experiment mode, the program asks the participant to respond
        begin
           experiment := false; //sets the experiment mode off
           responseLabel.Visible := false; //hides the response question

           {records each of participants' response in an array of string}
           responseRecord (Key);
           {checks if it is a reversal by checking if the response if different from the last time of the current procdure,
           and if it is, increases the reversal variable by one}
           if (Key <> lastResponseA) and (currentBlock = 1) then Inc (reversal);
           if (Key <> lastResponseB) and (currentBlock = 2) then Inc (reversal);
           {records this respose as the last response}
           if (currentBlock = 1) then lastResponseA := Key;
           if (currentBlock = 2) then lastResponseB := Key;

           {check if enough reversals have happended, if so, it ends the experiment and save the data}
           if (reversal - 1 > stopRule) then
             begin
               finishTime := DateTimeToStr (Now); //records the time and date when participants' finish the experiment
               saveResults; //save the data
               ShowMessage('Muito obrigado por sua participação! O aplicativo irá se fechar agora. Pressione Enter para encerrar.');
               Application.Terminate; //closes the experiment
               ShowWindow(hTaskBar, SW_SHOW); //Displays the windows taskbar again
             end;

           {changes the next stimuli intensity}
           if (currentBlock = 1) then currentStimulus1 := increaseOrDecrease (Key, currentStimulus1);
           if (currentBlock = 2) then currentStimulus2 := increaseOrDecrease (Key, currentStimulus2);

           {if there is not enough reversals then continue the experiment by presenting the interval screen}
           StairCaseInterval;
        end;
      end;

  end;


{Will check for the stimuli range and then increase or decrease the picture index}
function increaseOrDecrease (Key: Char; index : Integer ) : Integer;
  begin
    if (Key = #49) then //if participant press 1 arrow (neutral face)
      begin
        if (index < HIGHIEST_STIMULUS) then index := index + UP;
      end
    else if (Key = #50) then //if participant press 2 arrow (emotion)
      begin
        if (index > LOWEST_STIMULUS) then index := index - DOWN;
      end;

      result := index;
  end;


{Sets a time interval to hide the fixation cross, present stimuli and collect participants' response}
procedure TformMain.presentationTimeTimer(Sender: TObject);
  begin
    {clears previous stimuli}
    cross.Visible := false; //makes the cross invisible
    {load and show the stimulus}
    if (currentBlock = 1) then faceImage.Picture.LoadFromFile(emotion + InttoStr(currentStimulus1) + '.bmp'); //Load the image
    if (currentBlock = 2) then faceImage.Picture.LoadFromFile(emotion + InttoStr(currentStimulus2) + '.bmp'); //Load the image
    faceImage.Visible := true; //makes the image visible
    StimuliTimer.Enabled := true; //present the stimuli for a given time and then asks the question
    presentationTime.Enabled := false; //turns the timer off because the timer will run again otherwise
  end;

{Makes the stimuli invisible after a given time}
procedure TformMain.StimuliTimerTimer(Sender: TObject);
begin
   faceImage.Visible := false; //hides de stimuli
   responseLabel.Visible := true; //shows the response question
   experiment:= true;//asks for response (turns the experiment mode on)
   StimuliTimer.Enabled := false; //turns off the timer
end;

  {records each of participants' response in each array of the current method}
  procedure  responseRecord (Key : Char);
  var
    arraySize : Integer;
  begin
    if (currentBlock = 1) then
      begin
        SetLength(responsesBlockA, trialsA); //increases the array size
        responsesBlockA [trialsA-1] := Key;  //records the response
        {records the reversals}
        if ((Key <> lastResponseA) and (reversal-1 > EXCLUDED_TRIALS)) then
          begin
            arraySize := Length(reversalIntensityA); //gets the lenght of the array of recorded reversals
            SetLength(reversalIntensityA,arraySize+1); //increase array size
            reversalIntensityA [arraySize] := currentStimulus1 * PERCENT_MULTIPLYER; //records the current stimulus intensity
          end;
      end;

    if (currentBlock = 2) then
      begin
        SetLength(responsesBlockB, trialsB); //increases the array size
        responsesBlockB [trialsB-1] := Key; //records the response
        {records the reversals}
        if ((Key <> lastResponseB) and (reversal-1 > EXCLUDED_TRIALS)) then
          begin
            arraySize := Length(reversalIntensityB);//gets the lenght of the array of recorded reversals
            SetLength(reversalIntensityB,arraySize+1); //increase array size
            reversalIntensityB [arraySize] := currentStimulus2 * PERCENT_MULTIPLYER; //records the current stimulus intensity
          end;
      end;
  end;


procedure TformMain.saveResults;
  var
   myFile : TextFile;
   text   : string;
   i, total, stimulusNumb, result : Integer;
   meanA, meanB, totalMean : Double;
  begin
    AssignFile(myFile, '_participante#'+pNumber+'_'+pName+'_'+emotion+'.txt');   //assing a file to be created or changed
    Rewrite(myFile); //Opens a file as new - discards existing contents if file exists
    total := 0;

   WriteLn(myFile, 'Participante #' + pNumber); //write participant's number
   WriteLn(myFile, 'Nome: ' + pName); //write participant's name
   WriteLn (myFile, 'Sexo: ' + sex); //write participant's sex
   WriteLn (myFile, 'Hora de início: ' + startTime); //time of the begining of experiment
   WriteLn (myFile, 'Hora de término: ' + finishTime); //time of the end of experiment
   WriteLn (myFile, 'Regra de parada: ' + IntToStr(stopRule) + ' reversões'); //Stop Rule (how many reversals to end)
   WriteLn (myFile, 'Emoção escolhida: ' + emotion); //the emotion that the experimenter chose

   {saves the results of block A}
   WriteLn(myFile, 'Results from Block A (total de trials: ' + IntToStr (trialsA) + '): ');
   for i := Low (responsesBlockA) to High (responsesBlockA) do  //This loops write the array
    begin
      stimulusNumb := StrToInt(stimuliSequenceA [i]);
      result := stimulusNumb * PERCENT_MULTIPLYER; //converts the stimulus intensity to percentage
      WriteLn (myFile, 'Estímulo: ' + IntToStr (result) + '% - Resposta: ' + responsesBlockA[i]); //response and stimuli
    end;
    {records the reversals of blockA}
    Writeln(myFile,'Abaixo as reversões do bloco A, exluíndo as duas primeiras reversões do experimento quando for o caso:');
    if (Length(reversalIntensityA) > 0)then
      begin
        for i := Low(reversalIntensityA) to High(reversalIntensityA) do
          begin
            Inc (total, reversalIntensityA [i]);
            WriteLn(myFile, 'Reversão A: ' + IntToStr(reversalIntensityA [i]) + '%');
          end;
        meanA := total/(Length(reversalIntensityA));
      end;
    WriteLn(myFile, 'Média da reversão A excluíndo as duas primeiras reversões: ' + FloatToStr(meanA) + '%'); //writes the mean of block A


    total := 0; //sets the total to zero to calculate again in the B block

   {save the results of block B}
   WriteLn(myFile, 'Results from Block B (total de trials: ' + IntToStr (trialsB) + '): ');
   for i := Low (responsesBlockB) to High (responsesBlockB) do  //This loops write the array
    begin
      stimulusNumb := StrToInt(stimuliSequenceB [i]);
      result := stimulusNumb * PERCENT_MULTIPLYER; //converts the stimulus intensity to percentage
      WriteLn (myFile, 'Estímulo: ' + IntToStr (result) + '% - Resposta: ' + responsesBlockB[i]); //response and stimuli
    end;
    {records the reversals of blockB}
    Writeln(myFile,'Abaixo as reversões do bloco B, exluíndo as duas primeiras reversões do experimento quando for o caso:');
    if (Length(reversalIntensityB) > 0)then
      begin
        for i := Low(reversalIntensityB) to High(reversalIntensityB) do
          begin
            Inc (total, reversalIntensityB [i]);
            WriteLn(myFile, 'Reversão B: ' + IntToStr(reversalIntensityB [i]) + '%');
          end;
        meanB := total/(Length(reversalIntensityB));
      end;
    WriteLn(myFile, 'Média da reversão B excluíndo as duas primeiras reversões: ' + FloatToStr(meanB) + '%');

    {save the total mean}
    totalMean := (meanA + meanB)/2;
    WriteLn(myFile, 'Média Total excluíndo as duas primeiras reversões: ' + FloatToStr(totalMean) + '%'); //Writes the total mean

    CloseFile(myFile);
  end;


{Top menu options}
{On clicking in the about setting}
procedure TformMain.sobreClick(Sender: TObject);
begin
 credits.about.Show;
end;
{On clicking in the instruction option}
procedure TformMain.instrucaoClick(Sender: TObject);
begin
  Instrucoes.instructionsScreen.Show;
end;

{On clicking the 'fechar' menu}
procedure TformMain.fecharClick(Sender: TObject);
begin
  Application.Terminate; //closes the experiment
end;

{When the form is closed}
procedure TformMain.FormClose(Sender: TObject; var Action: TCloseAction);
  begin
    ShowWindow(hTaskBar, SW_SHOW); //Displays the windows taskbar again
  end;


end.
