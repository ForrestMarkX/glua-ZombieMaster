// Created by Crowbar 0.29.0.0

$ModelName "Male_pi.mdl"

$Model "male_pi" "male_pi_reference.smd" {

	eyeball "eye_right" "ValveBiped.Bip01_Head1" -1.265000 -3.575000 67.870004 "eyeball_r" 1 4 "iris_unused" 0.63
	eyeball "eye_left" "ValveBiped.Bip01_Head1" 1.206000 -3.575000 67.876001 "eyeball_l" 1 -4 "iris_unused" 0.63


	mouth 0 "mouth" "ValveBiped.Bip01_Head1" 0 1 0

	$Include "male_pi_flex.qci"
}

$Include "male_pi_lod.qci"

$SurfaceProp "flesh"

$Contents "solid"

$EyePosition 0 0 70

$MaxEyeDeflection 90

$CDMaterials "models\Humans\Male\Group02\"
$CDMaterials "models\Humans\Male\"
$CDMaterials "models\humans\male\"

$Attachment "eyes" "ValveBiped.Bip01_Head1" 3.98 -3.72 0.03 rotate 0 -80.1 -90
$Attachment "mouth" "ValveBiped.Bip01_Head1" 1.2 -5.7 0 rotate 0 -80 -90
$Attachment "chest" "ValveBiped.Bip01_Spine2" 5 4 0 rotate 0 90 90
$Attachment "forward" "ValveBiped.forward" 0 0 0 rotate 0 0 0
$Attachment "anim_attachment_RH" "ValveBiped.Anim_Attachment_RH" 0 0 0 rotate -90 -90 0
$Attachment "anim_attachment_LH" "ValveBiped.Anim_Attachment_LH" 0 0 0 rotate -90 -90 0
$Attachment "anim_attachment_head" "ValveBiped.Bip01_Head1" 0 0 0 rotate -90 -90 0

// $Include "male_pi_box.qci"

$Include "male_pi_bone.qci"

$Include "male_pi_animation.qci"

$Include "male_pi_collision.qci"
