extends Node

# Singleton for managing disk operations across the game

signal disk_inserted(disk_name: String)
signal disk_ejected(disk_name: String)
signal disk_content_accessed(disk_name: String, content: Dictionary)

var inserted_disks: Array[String] = []
var max_disks: int = 5

# Disk definitions with alien classification data
var disk_database: Dictionary = {
	"Disk1": {
		"name": "CLASS_1",
		"label": "Class 1 Alien Classification Data",
		"content": "Complete biological and chemical data for Class 1 alien species",
		"files": ["species_overview.txt", "weight_classes.csv", "blood_types.txt", "eye_colors.txt", "liquid_ratios.csv"],
		"species": "Class 1",
		"weight_range": "130-150 kg",
		"blood_types": ["X-Positive", "O-Negative", "Z-Flux"],
		"eye_colors": ["Yellow", "Orange", "White"],
		"color": Color.YELLOW
	},
	"Disk2": {
		"name": "CLASS_2", 
		"label": "Class 2 Alien Classification Data",
		"content": "Complete biological and chemical data for Class 2 alien species",
		"files": ["species_overview.txt", "weight_classes.csv", "blood_types.txt", "eye_colors.txt", "liquid_ratios.csv"],
		"species": "Class 2",
		"weight_range": "80-100 kg",
		"blood_types": ["A-Neutral", "B-Static"],
		"eye_colors": ["Green", "Cyan", "Amber"],
		"color": Color.GREEN
	},
	"Disk3": {
		"name": "CLASS_3",
		"label": "Class 3 Alien Classification Data",
		"content": "Complete biological and chemical data for Class 3 alien species", 
		"files": ["species_overview.txt", "weight_classes.csv", "blood_types.txt", "eye_colors.txt", "liquid_ratios.csv"],
		"species": "Class 3",
		"weight_range": "200-250 kg",
		"blood_types": ["B-Volatile", "C-Pulse"],
		"eye_colors": ["Blue", "Indigo", "Red"],
		"color": Color.BLUE
	},
	"Disk4": {
		"name": "CLASS_4",
		"label": "Class 4 Alien Classification Data",
		"content": "Complete biological and chemical data for Class 4 alien species",
		"files": ["species_overview.txt", "weight_classes.csv", "blood_types.txt", "eye_colors.txt", "liquid_ratios.csv"],
		"species": "Class 4",
		"weight_range": "50-70 kg",
		"blood_types": ["C-Stable", "D-Light"],
		"eye_colors": ["Purple", "Violet", "Magenta"],
		"color": Color.PURPLE
	}
}

func _ready() -> void:
	# Connect to global signals if needed
	pass

# Helper function to repeat strings (GDScript doesn't support string * int)
func repeat_string(text: String, count: int) -> String:
	var result = ""
	for i in range(count):
		result += text
	return result

func get_disk_info(disk_name: String) -> Dictionary:
	if disk_name in disk_database:
		return disk_database[disk_name].duplicate()
	return {}

func can_insert_disk() -> bool:
	return inserted_disks.size() < max_disks

func insert_disk(disk_name: String) -> bool:
	if not can_insert_disk():
		push_error("Cannot insert disk: Maximum capacity reached")
		return false
	
	if disk_name in inserted_disks:
		push_error("Disk already inserted: " + disk_name)
		return false
	
	if not disk_name in disk_database:
		push_error("Unknown disk: " + disk_name)
		return false
	
	inserted_disks.append(disk_name)
	emit_signal("disk_inserted", disk_name)
	print("Disk inserted: ", disk_name)
	return true

func eject_disk(disk_name: String) -> bool:
	if not disk_name in inserted_disks:
		push_error("Disk not inserted: " + disk_name)
		return false
	
	inserted_disks.erase(disk_name)
	emit_signal("disk_ejected", disk_name)
	print("Disk ejected: ", disk_name)
	return true

func get_inserted_disks() -> Array[String]:
	return inserted_disks.duplicate()

func is_disk_inserted(disk_name: String) -> bool:
	return disk_name in inserted_disks

func get_disk_content(disk_name: String) -> String:
	if not disk_name in disk_database:
		return "ERROR: Unknown disk"
	
	var disk_data = disk_database[disk_name]
	var content = ""
	
	content += repeat_string("=", 50) + "\n"
	content += "SPECIES: " + disk_data["species"] + "\n"
	content += "CLASSIFICATION: " + disk_data["name"] + "\n"
	content += "WEIGHT RANGE: " + disk_data["weight_range"] + "\n"
	content += repeat_string("=", 50) + "\n\n"
	
	content += "DESCRIPTION:\n" + disk_data["content"] + "\n\n"
	
	content += "AVAILABLE FILES:\n"
	for file in disk_data["files"]:
		content += "  > " + file + "\n"
	
	content += "\nBLOOD TYPES: " + str(disk_data["blood_types"]) + "\n"
	content += "EYE COLORS: " + str(disk_data["eye_colors"]) + "\n"
	
	emit_signal("disk_content_accessed", disk_name, disk_data)
	return content

func get_horror_message(disk_name: String) -> String:
	# No longer using horror messages for alien classification
	return ""

func clear_all_disks() -> void:
	for disk in inserted_disks.duplicate():
		eject_disk(disk)

# Generate detailed file content for alien classification
func get_file_content(disk_name: String, filename: String) -> String:
	if not disk_name in disk_database:
		return "ERROR: DISK NOT FOUND"
	
	match disk_name:
		"Disk1":
			return _get_class1_file_content(filename)
		"Disk2":
			return _get_class2_file_content(filename)
		"Disk3":
			return _get_class3_file_content(filename)
		"Disk4":
			return _get_class4_file_content(filename)
		_:
			return "ERROR: INVALID DISK"

func _get_class1_file_content(filename: String) -> String:
	match filename:
		"species_overview.txt":
			return """CLASS 1 - SPECIES CLASSIFICATION
=====================================
DESIGNATION: Class 1 Alien Species
ORIGIN: Unknown System, Sector 7
DISCOVERY DATE: 1971.03.15
WEIGHT RANGE: 130-150 kg
THREAT ASSESSMENT: VARIABLE

PHYSICAL CHARACTERISTICS:
- Bipedal humanoid structure
- Average height: 2.1-2.4 meters
- Distinctive cranial ridges
- Three-chambered heart system
- Regenerative tissue capabilities

CLASSIFICATION NOTES:
Species shows significant variation based on:
1. Weight classification (3 distinct ranges)
2. Eye color phenotypes
3. Blood type variations
4. Liquid composition ratios

VIABILITY ASSESSMENT:
Depends on specific subclass characteristics.
Refer to weight_classes.csv and liquid_ratios.csv
for detailed classification criteria."""
		
		"weight_classes.csv":
			return "CSV_TABLE"  # Special marker for CSV display
		
		"blood_types.txt":
			return """ZORATH PRIME BLOOD TYPE ANALYSIS
===============================
VALID BLOOD TYPES:
- X-Positive: Common variant (60% of population)
- O-Negative: Rare variant (25% of population)  
- Z-Flux: Unstable variant (15% of population)

BLOOD TYPE CHARACTERISTICS:
X-Positive:
- Stable coagulation
- Compatible with Earth atmosphere
- Low toxicity levels

O-Negative:
- Enhanced oxygen capacity
- Requires specialized containment
- Medium toxicity levels

Z-Flux:
- Highly reactive components
- Unstable in Earth conditions
- High toxicity levels
- CAUTION: May affect classification"""
		
		"eye_colors.txt":
			return """ZORATH PRIME EYE COLOR CLASSIFICATION
====================================
VALID EYE COLORS:
- Yellow: Standard phenotype
- Orange: Variant phenotype
- White: Rare phenotype

EYE COLOR SIGNIFICANCE:
Eye color directly correlates with:
- Metabolic rate
- Liquid composition ratios
- Behavioral patterns
- Viability assessment

CLASSIFICATION NOTES:
- Yellow eyes: Generally stable
- Orange eyes: Moderate risk factors
- White eyes: High risk, requires careful evaluation

Use eye color as primary classification criterion
in conjunction with weight and liquid ratios."""
		
		"liquid_ratios.csv":
			return """WEIGHT,EYE_COLOR,LIQUID_A,LIQUID_B,LIQUID_C
130-139,Yellow,31,51,18
130-139,Orange,28,49,23
130-139,White,33,53,14
140-145,Yellow,19,62,19
140-145,Orange,21,58,21
140-145,White,18,64,18
146-150,Yellow,11,38,51
146-150,Orange,9,42,49
146-150,White,12,36,52"""
		
		_:
			return "ZORATH PRIME FILE: " + filename + "\nFILE NOT FOUND OR ACCESS RESTRICTED"

func _get_class2_file_content(filename: String) -> String:
	match filename:
		"species_overview.txt":
			return """KLYTHERA - SPECIES CLASSIFICATION
=================================
DESIGNATION: Klythera
ORIGIN: Klytherian Nebula, Unknown Sector
DISCOVERY DATE: 1971.07.22
WEIGHT RANGE: 80-100 kg
THREAT ASSESSMENT: LOW TO MODERATE

PHYSICAL CHARACTERISTICS:
- Quadrupedal with prehensile appendages
- Average length: 1.8-2.2 meters
- Crystalline exoskeleton structures
- Dual respiratory systems
- Photosynthetic capabilities

BEHAVIORAL NOTES:
- Generally docile when isolated
- Shows intelligence patterns
- Responds to light stimulation
- Communicates via bio-luminescence

CLASSIFICATION CRITERIA:
Weight and eye color are primary factors.
Blood type compatibility affects viability.
Liquid ratios must be within acceptable ranges."""
		
		"weight_classes.csv":
			return "CSV_TABLE"
		
		"blood_types.txt":
			return """KLYTHERA BLOOD TYPE ANALYSIS
===========================
VALID BLOOD TYPES:
- A-Neutral: Standard variant (70% of population)
- B-Static: Energized variant (30% of population)

BLOOD TYPE CHARACTERISTICS:
A-Neutral:
- Chemically stable
- Low energy output
- Compatible with standard containment

B-Static:
- Electrically active
- Requires insulated containment
- Higher energy output
- May interfere with equipment"""
		
		"eye_colors.txt":
			return """KLYTHERA EYE COLOR CLASSIFICATION
=================================
VALID EYE COLORS:
- Green: Standard bio-luminescence
- Cyan: Enhanced bio-luminescence  
- Amber: Rare bio-luminescence variant

EYE COLOR PROPERTIES:
Green:
- Standard light emission
- Normal metabolic rate
- Stable liquid ratios

Cyan:
- Enhanced light emission
- Increased metabolic activity
- Variable liquid ratios

Amber:
- Intense light emission
- High metabolic rate
- Extreme liquid variations"""
		
		"liquid_ratios.csv":
			return """WEIGHT,EYE_COLOR,LIQUID_A,LIQUID_B,LIQUID_C
80-89,Green,42,38,20
80-89,Cyan,38,42,20
80-89,Amber,44,36,20
90-95,Green,32,28,40
90-95,Cyan,28,32,40
90-95,Amber,34,26,40
96-100,Green,22,18,60
96-100,Cyan,18,22,60
96-100,Amber,24,16,60"""
		
		_:
			return "KLYTHERA FILE: " + filename + "\nFILE NOT FOUND OR ACCESS RESTRICTED"

func _get_class3_file_content(filename: String) -> String:
	match filename:
		"species_overview.txt":
			return """VAXILON - SPECIES CLASSIFICATION
===============================
DESIGNATION: Vaxilon
ORIGIN: Vaxilon Prime, Outer Rim
DISCOVERY DATE: 1971.11.08
WEIGHT RANGE: 200-250 kg
THREAT ASSESSMENT: HIGH

PHYSICAL CHARACTERISTICS:
- Large bipedal structure
- Average height: 3.2-3.8 meters
- Armored carapace plating
- Multiple sensory organs
- Venomous glands detected

BEHAVIORAL WARNINGS:
- Highly aggressive when threatened
- Territorial instincts strong
- Shows problem-solving intelligence
- Resistant to standard containment

CLASSIFICATION IMPORTANCE:
Proper classification is CRITICAL.
Misclassification may result in containment breach.
All liquid ratios must be verified twice."""
		
		"weight_classes.csv":
			return "CSV_TABLE"
		
		"blood_types.txt":
			return """VAXILON BLOOD TYPE ANALYSIS
===========================
VALID BLOOD TYPES:
- B-Volatile: Unstable variant (55% of population)
- C-Pulse: Rhythmic variant (45% of population)

BLOOD TYPE CHARACTERISTICS:
B-Volatile:
- Highly reactive
- Corrosive properties
- Requires specialized handling
- DANGER: May damage equipment

C-Pulse:
- Rhythmic pressure variations
- Bio-electric activity
- Affects liquid composition
- May influence classification results"""
		
		"eye_colors.txt":
			return """VAXILON EYE COLOR CLASSIFICATION
===============================
VALID EYE COLORS:
- Blue: Standard predator variant
- Indigo: Enhanced predator variant
- Red: Alpha predator variant

TACTICAL ASSESSMENT:
Blue:
- Standard threat level
- Normal aggression patterns
- Predictable behavior

Indigo:
- Elevated threat level
- Enhanced aggression
- Tactical intelligence displayed

Red:
- MAXIMUM threat level
- Extreme aggression
- Advanced tactical awareness
- CAUTION: May attempt escape"""
		
		"liquid_ratios.csv":
			return """WEIGHT,EYE_COLOR,LIQUID_A,LIQUID_B,LIQUID_C
200-219,Blue,52,28,20
200-219,Indigo,48,32,20
200-219,Red,54,26,20
220-235,Blue,42,38,20
220-235,Indigo,38,42,20
220-235,Red,44,36,20
236-250,Blue,32,28,40
236-250,Indigo,28,32,40
236-250,Red,34,26,40"""
		
		_:
			return "VAXILON FILE: " + filename + "\nFILE NOT FOUND OR ACCESS RESTRICTED"

func _get_class4_file_content(filename: String) -> String:
	match filename:
		"species_overview.txt":
			return """NEXIS-7 - SPECIES CLASSIFICATION
===============================
DESIGNATION: Nexis-7
ORIGIN: Nexis System, 7th Planet
DISCOVERY DATE: 1972.01.14
WEIGHT RANGE: 50-70 kg
THREAT ASSESSMENT: UNKNOWN

PHYSICAL CHARACTERISTICS:
- Small humanoid structure
- Average height: 1.2-1.5 meters
- Translucent skin tissue
- Enlarged cranium (brain-to-body ratio 1:3)
- Telekinetic abilities confirmed

PSYCHOLOGICAL PROFILE:
- Highly intelligent (IQ estimated >300)
- Peaceful demeanor observed
- Attempts communication through telepathy
- Shows emotional responses to stimuli

SPECIAL NOTES:
Classification difficulty due to psychic interference.
Standard equipment may malfunction near specimens.
Liquid ratios appear to correlate with psychic ability."""
		
		"weight_classes.csv":
			return "CSV_TABLE"
		
		"blood_types.txt":
			return """NEXIS-7 BLOOD TYPE ANALYSIS
==========================
VALID BLOOD TYPES:
- C-Stable: Psychically inert (40% of population)
- D-Light: Psychically active (60% of population)

BLOOD TYPE CHARACTERISTICS:
C-Stable:
- No psychic interference
- Standard biological functions
- Normal liquid ratios
- Safe for handling

D-Light:
- Active psychic fields
- May affect nearby equipment
- Variable liquid compositions
- Requires psychic shielding during analysis"""
		
		"eye_colors.txt":
			return """NEXIS-7 EYE COLOR CLASSIFICATION
===============================
VALID EYE COLORS:
- Purple: Standard psychic variant
- Violet: Enhanced psychic variant
- Magenta: Rare psychic variant

PSYCHIC CORRELATION:
Purple:
- Low-level telepathy
- Minor telekinesis
- Stable psychic output

Violet:
- Moderate telepathy
- Significant telekinesis
- Variable psychic output

Magenta:
- Advanced telepathy
- Powerful telekinesis
- Unpredictable psychic events
- WARNING: May influence classification decisions"""
		
		"liquid_ratios.csv":
			return """WEIGHT,EYE_COLOR,LIQUID_A,LIQUID_B,LIQUID_C
50-59,Purple,62,18,20
50-59,Violet,58,22,20
50-59,Magenta,64,16,20
60-65,Purple,52,28,20
60-65,Violet,48,32,20
60-65,Magenta,54,26,20
66-70,Purple,42,38,20
66-70,Violet,38,42,20
66-70,Magenta,44,36,20"""
		
		_:
			return "CLASS 4 FILE: " + filename + "\nFILE NOT FOUND OR ACCESS RESTRICTED"

		_:
			return "CLASS 4 FILE: " + filename + "\nFILE NOT FOUND OR ACCESS RESTRICTED"
