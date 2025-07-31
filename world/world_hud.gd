extends Control

@onready var save_data := Save.data as SaveData
@onready var g: RichTextLabel = $G
@onready var a: RichTextLabel = $A
@onready var p: RichTextLabel = $P
@onready var t: RichTextLabel = $T

const G_MAX = 100000
const A_MAX = 100000
const P_MAX = 100000
const T_MAX = 80000

func _ready():
	update()

func update():
	g.text = "Glycosine: \n%.1f" % Global.save_data.energy_g
	if save_data.energy_g > G_MAX :
		a.text = "Alkaloid Balance Achieved!"

	var amount_a = save_data.energy_a
	a.text = "Alkaloids: \n%.1f" % amount_a
	if amount_a > A_MAX :
		a.text = "Alkaloid Balance Achieved!"
	if amount_a == 0:
		a.hide()
	else: 
		a.show()
	
	var amount_p = Global.save_data.energy_p
	p.text = "Ployphenols: \n%.1f" % amount_p
	if amount_a > P_MAX :
		a.text = "Ployphenol Balance Achieved!"
	if amount_p == 0:
		p.hide()
	else: 
		p.show()
	
	var amount_t = Global.save_data.energy_t
	t.text = "Terpenes: \n%.1f" % amount_t
	if amount_a > T_MAX :
		a.text = "Terpenes Balance Achieved!"
	if amount_t == 0:
		t.hide()
	else: 
		t.show()
	
