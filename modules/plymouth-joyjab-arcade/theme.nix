{
  stdenv,
  writeTextFile,
}: let
  # Ensure this points to your actual image file
  logoPng = ./logo.png;
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

        ### ROTATION LOGIC ###
        # spinner_max_third defines how many frames are in 1/3 of a rotation
        logo.spinner_max_third = 32;
        logo.spinner_max = logo.spinner_max_third * 3;
        logo.spinner_index = 0;

        # Pre-calculate rotated frames using the Sine function for "easing"
        real_index = 0;
        for (third = 0; third < 3; third++) {
          for (index = 0; index < logo.spinner_max_third; index++) {
            subthird = index / logo.spinner_max_third;
            # The Sin function creates the "speed up and slow down" effect
            angle = (third + ((Math.Sin(Math.Pi * (subthird - 0.5)) / 2) + 0.5)) / 3;
            logo.spinner_image[real_index] = logo.image.Rotate(2 * Math.Pi * angle);
            real_index++;
          }
        }

        # This function runs every frame
        fun refresh_callback () {
          logo.spinner_index = (logo.spinner_index + 1) % (logo.spinner_max * 2);
          # We divide by 2 here to slow the animation down slightly
          logo.sprite.SetImage(logo.spinner_image[Math.Int(logo.spinner_index / 2)]);
        }

        Plymouth.SetRefreshFunction(refresh_callback);
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