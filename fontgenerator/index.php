<?php

$post = array(
    "character_width" => 32,
    "character_height" => 48,
    
    "texture_width" => 32*16,
    "texture_height" => 48*6,

    "character_size" => 20,

    "color_red" => 0,
    "color_green" => 0,
    "color_blue" => 0,

    "magenta_bg" => "",
    
    "font_path" => "",
    "font_temp_path" => "",
);

if( isset( $_POST['form_submitted'] ) ) {

    foreach( $post as $key => $value ) {
        if( isset( $_POST[ $key ] ) )
            $post[ $key ] = $_POST[ $key ];
    }

    // font
    $font = 5;
    
    if( $_FILES["font"]["error"] == 0 ) {
        $post["font_path"] = $_FILES["font"]["name"];
        $file_ext = end( explode( ".", $post["font_path"] ) );

        $post["font_temp_path"] = $_FILES["font"]["tmp_name"];
        
        if( $file_ext == "gdf" )
            $font = imageloadfont( $post["font_temp_path"] );
    }

    // create image
    
    $post["character_width"] = imagefontwidth( $font );
    $post["character_height"] = imagefontheight( $font );
    
    $post["texture_width"] = $post["character_width"] * 16;
    $post["texture_height"] = $post["character_height"] * 6;
    
    $image = imagecreate( $post["texture_width"], $post["texture_height"] );
    
    // background
    if( $post["magenta_bg"] == "on" )
        $transp = imagecolorallocatealpha( $image, 255,0, 255, 0 );
    else // transparent (but appear as black in CS)
        $transp = imagecolorallocatealpha( $image, 255, 255, 255, 127 );

    // text color
    $color = imagecolorallocate( $image, $post["color_red"], $post["color_green"], $post["color_blue"] );

    $ascii = array(
        " !\"#$%&'()*+,-./",
        "0123456789:;<=>?",
        "@ABCDEFGHIJKLMNO",
        "PQRSTUVWXYZ[\]^_",
        "`abcdefghijklmno",
        "pqrstuvwxyz{|}~µ",
    );

    $height_offset = 0;

    foreach( $ascii as $line ) {
        imagestring( $image, $font, 0, $height_offset, $line, $color );

        $height_offset += $post["character_height"];
    }
    

    imagepng( $image, "placeholder_image.png" );
    imagedestroy( $image );
}
?>

<html>
<head>
    <title>CraftStudio Font Generator</title>
    <style type="text/css">
    </style>
</head>
<body>
    <H1>CraftStudio Font Generator</H1>

    <p>
        This tool generate a transparent .png image (from a .gdf font file) that you can copy and paste straight to CraftStudio's font editor. <br>
        Get the .gdf font file on your drive, then select your color and click on "Create color" button to generate the image. <br>
        <br>
        Creates .gdf font file with the desired character height and width with the <a href="http://www.wedwick.com/wftopf.exe">Windows Font to PHP Font</a> tool (Windows only). <br>
        <br>
        If the image does not seems to update properly, force the update of the cache (Ctrl+F5 on Windows). <br>
        <br>
        <a href="http://florentpoujol.fr/2013/07/22/how-to-easily-create-fonts-for-craftstudio/">See the full bog post about creating fonts for CraftStudio.</a> <br>
        <br>
        <a href="index.php.txt">Download the source of this script</a> v2<br>
    </p>

    <hr>

    <form action="index.php" method="post" enctype="multipart/form-data">

        Font file (.gdf) :<br>
        <input type="file" name="font" placeholder="Path to the font file" size="50"> <br>
        <br>
        Color :<br>
        Red <input type="text" name="color_red" value="<?php echo $post["color_red"]; ?>" > <br>
        Green <input type="text" name="color_green" value="<?php echo $post["color_green"]; ?>" > <br>
        Blue <input type="text" name="color_blue" value="<?php echo $post["color_blue"]; ?>" > <br>
        <br>
      
        <?php
        $checked = "";
        if( $post["magenta_bg"] == "on" )
            $checked = "checked='checked' ";
        ?>
        <label for="magenta_bg">Magenta background <input type="checkBox" id="magenta_bg" name="magenta_bg" <?php echo $checked; ?>> </label> <br> 
        A transparent background may appear black in CraftStudio (yet it appears transparent in image editing tools like Paint.net). <br>
        If that's the case, tick the box to get a magenta background to the image that will appear transparent in CraftStudio. <br>
         
        <br>

        <br>
        <input type="submit" name="form_submitted" value="Create image">
        <br>
    </form>

    <hr>
    <br>
    Characters size : <?php echo $post["character_width"]; ?> * <?php echo $post["character_height"]; ?><br>
    Texture size : <?php echo $post["texture_width"]; ?> * <?php echo $post["texture_height"]; ?><br>
    Right click on the image > Copy image. Then paste in CraftStudio Font editor. <br>
    <br>

    <img src="placeholder_image.png" alt="placeholder_image">
</body>
</html>
