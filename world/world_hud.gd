extends Control

@onready var save_data := Save.data as SaveData
@onready var g: RichTextLabel = $G
@onready var a: RichTextLabel = $A
@onready var p: RichTextLabel = $P
@onready var t: RichTextLabel = $T

const G_LABEL = "Glycosine"
const A_LABEL = "Alkaloid"
const P_LABEL = "Polyphenol"
const T_LABEL = "Terpene"
const COMPOUND_SUCCESS = "balance achieved!"

const G_MAX = 100000
const A_MAX = 100000
const P_MAX = 100000
const T_MAX = 80000

func _ready():
	update()

func update():
	var amount_g = save_data.energy_g
	var amount_a = save_data.energy_a
	var amount_p = save_data.energy_p
	var amount_t = save_data.energy_t
	
	g.text = "%s: \n%.1f" % [G_LABEL, amount_g]
	if save_data.energy_g > G_MAX:
		g.text = "%s %s" % [G_LABEL, COMPOUND_SUCCESS]

	a.text = "%s: \n%.1f" % [A_LABEL, amount_a]
	if amount_a > A_MAX:
		a.text = "%s %s" % [A_LABEL, COMPOUND_SUCCESS]
	if amount_a != 0:
		a.show()
	
	p.text = "%s: \n%.1f" % [P_LABEL, amount_p]
	if amount_a > P_MAX:
		p.text = "%s %s" % [P_LABEL, COMPOUND_SUCCESS]
	if amount_p != 0:
		p.show()
	
	t.text = "%s: \n%.1f" % [T_LABEL, amount_t]
	if amount_a > T_MAX:
		t.text = "%s %s" % [T_LABEL, COMPOUND_SUCCESS]
	if amount_t != 0:
		t.show()
	
