{
  stdenv,
  writeTextFile,
}: let
  logoPng = ./logo.png; #this needs to be a png btw
in
  stdenv.mkDerivation {
    name = "plymouth-theme-joyjab";

    src = writeTextFile {
      name = "theme.script";
      text = ''
        center_x = Window.GetWidth() / 2;
        center_y = Window.GetHeight() / 2;

        # Set background to black
        Window.SetBackgroundTopColor(0, 0, 0);
        Window.SetBackgroundBottomColor(0, 0, 0);

        ### LOGO SETUP ###
        logo.image = Image("logo.png");
        logo.sprite = Sprite(logo.image);
        logo.sprite.SetPosition(
          center_x - (logo.image.GetWidth() / 2),
          center_y - (logo.image.GetHeight() / 2),
          1
        );
      '';
    };

    dontUnpack = true;

    installPhase = ''
      themeDir="$out/share/plymouth/themes/joyjab-arcade"
      mkdir -p $themeDir

      cp $src $themeDir/joyjab-arcade.script
      cp ${logoPng} $themeDir/logo.png

      cat << EOF > $themeDir/joyjab-arcade.plymouth
      [Plymouth Theme]
      Name=JoyJab Arcade
      ModuleName=script

      [script]
      ImageDir=$themeDir
      ScriptFile=$themeDir/joyjab-arcade.script
      EOF
    '';
  }