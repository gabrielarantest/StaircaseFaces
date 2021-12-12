program Faces;

uses
  Vcl.Forms,
  Main in 'Main.pas' {formMain},
  Instrucoes in 'Instrucoes.pas' {instructionsScreen},
  credits in 'credits.pas' {about};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TformMain, formMain);
  Application.CreateForm(TinstructionsScreen, instructionsScreen);
  Application.CreateForm(Tabout, about);
  Application.Run;
end.
