[gd_scene load_steps=6 format=3 uid="uid://c4k3j2l5m7n8p"]

[ext_resource type="Script" path="res://Machine.gd" id="1_k2q3r"]

[sub_resource type="BoxMesh" id="BoxMesh_abc12"]
size = Vector3(1, 1, 1)

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_j5k2l"]
bg_color = Color(0.2, 0.2, 0.2, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.8, 0.8, 0.8, 1)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_vptex"]
albedo_texture = SubResource("ViewportTexture_vp123")

[sub_resource type="ViewportTexture" id="ViewportTexture_vp123"]
viewport_path = NodePath("SubViewport")

[node name="Machine" type="Node3D"]
script = ExtResource("1_k2q3r")
metadata/_edit_group_ = true

[node name="MeshInstance3D" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
mesh = SubResource("BoxMesh_abc12")
surface_material_override/0 = SubResource("StandardMaterial3D_vptex")

[node name="SubViewport" type="SubViewport" parent="."]
transparent_bg = true
size = Vector2i(256, 128)

[node name="Control" type="Control" parent="SubViewport"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="RichTextLabel" type="RichTextLabel" parent="SubViewport/Control"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -100.0
offset_top = -50.0
offset_right = 100.0
offset_bottom = 50.0
grow_horizontal = 2
grow_vertical = 2
theme_override_styles/normal = SubResource("StyleBoxFlat_j5k2l")
bbcode_enabled = true
text = "[center][font_size=48]0[/font_size][/center]"

[node name="UpButton" type="Area3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.3, 0.7, -0.51)
collision_layer = 1
collision_mask = 1

[node name="MeshInstance3D" type="MeshInstance3D" parent="UpButton"]
mesh = SubResource("BoxMesh_btn")
material_override = SubResource("StandardMaterial3D_btn_up")

[node name="CollisionShape3D" type="CollisionShape3D" parent="UpButton"]
shape = SubResource("BoxShape3D_btn")

[node name="DownButton" type="Area3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.3, 0.7, -0.51)
collision_layer = 1
collision_mask = 1

[node name="MeshInstance3D" type="MeshInstance3D" parent="DownButton"]
mesh = SubResource("BoxMesh_btn")
material_override = SubResource("StandardMaterial3D_btn_down")

[node name="CollisionShape3D" type="CollisionShape3D" parent="DownButton"]
shape = SubResource("BoxShape3D_btn")

[sub_resource type="BoxMesh" id="BoxMesh_btn"]
size = Vector3(0.2, 0.2, 0.05)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_btn_up"]
albedo_color = Color(0, 1, 0, 1)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_btn_down"]
albedo_color = Color(1, 0, 0, 1)

[sub_resource type="BoxShape3D" id="BoxShape3D_btn"]
size = Vector3(0.2, 0.2, 0.05)
