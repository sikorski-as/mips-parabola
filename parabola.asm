# Projekt 1 MIPS
# Rysowanie paraboli w uk³adzie wspó³rzêdnych

.data

#rozmiar:		.space 4	# calkowity rozmiar pliku bmp (ilosc bajtow)
#offset:		.space 4	# offset - adres poczatku tablicy pikseli
#buffer:		.space 4	# bufor wczytywania tymczasowych danych

#height:		.space 4	# wysokosc tablicy pikseli
#width:			.space 4	# szerokosc tablicy pikseli (bez paddingu)
#padding:		.space 4	# ilosc bajtow paddingowych w wierszu

text_title:		.asciiz "MIPS Project - drawing a parabola\nArkadiusz Sikorski\n"
text_height_prompt:	.asciiz "Enter height of the output image:"
text_width_prompt:	.asciiz "Enter width of the output image:"
text_range_prompt:	.asciiz "Enter range of the scale (positive number):"
text_error:		.asciiz "An error occured, closing\n"
output:			.asciiz "output.bmp"

bm:			.ascii "BM"	# dwa znaki informuj¹ce, ¿e to jest bitmapa
.align 2				# wyrównaj do 4 bajtów
header:			.space 52	# nag³ówek bitmapy

# coefficients
.align 2				# wyrównaj do 4 bajtów
A:			.space 4
B:			.space 4
C:			.space 4
# colors
color_background:	.space 4
color_scale:		.space 4
color_parabola:		.space 4

# Rejestry zachowywane u¿ywane jako zmienne globalne:
# s0 - height (px)
# s1 - width (px)
# s2 - padding (bajty)
# s3 - width*3 + padding
# s4 - pointer of allocated memory for the bitmap
# s5 - range	--->	X <-s5, +s5>, Y <-s5, +s5>
# s6 - delta x, delta y (szerokoœæ liczbowa piksela, zapisane w Q16.16)
# s7 - deskryptor pliku

.globl main
.text
main:
	li $v0, 4
	la $a0, text_title
	syscall

load_coefficients:
	li $t2, -3			# zapisz wspó³czynnik A (Q16.16)
	sll $t2, $t2, 14
	sra $t2, $t2, 4
	sw $t2, A
	
	li $t1, -3			# zapisz wspó³czynnik B (Q16.16)
	sll $t1, $t1, 14
	sra $t1, $t1, 2
	sw $t1, B
	
	li $t0, 11			# zapisz wspó³czynnik C (Q16.16)
	sll $t0, $t0, 14
	sra $t0, $t0, 3
	sw $t0, C 

set_colors:
	li $t0, 0x00211A23
	sw $t0, color_background
	
	li $t0, 0x00302533
	sw $t0, color_scale
	
	li $t0, 0x00F9F9F9
	sw $t0, color_parabola

get_height: 				# czyta wysokosc obrazka
	li $v0, 4
	la $a0, text_height_prompt
	syscall
	
	li $v0, 5
	syscall
	
	move $s0, $v0 			# wczytaj do $s0 wysokoœæ obrazka
	
get_width: 				# czyta szerokosc obrazka
	li $v0, 4
	la $a0, text_width_prompt
	syscall
	
	li $v0, 5
	syscall
	
	move $s1, $v0 			# wczytaj do $s1 szerokoœæ obrazka (bez paddingu)
	
get_range: 				# czyta zakres skali
	li $v0, 4
	la $a0, text_range_prompt
	syscall
	
	li $v0, 5
	syscall
	
	move $s5, $v0 			# wczytaj do $s5 zakres liczbowy osi
	
compute_padding:
	move $t0, $s1
	mul $t0, $t0, 3			# t0 = szerokoœæ * 3
	andi $t0, $t0, 3		# t0 = (szerokoœæ * 3) MOD 4
	
	li $s2, 0			# domyœlnie zerowy padding
	beqz $t0, allocate_memory	# wyliczone modulo = 0, padding równy zero, skaczemy do nastêpnego fragmentu programu
	
	li $s2, 4			# jeœli modulo > 0, liczymy ile bajtów paddingu trzeba dodaæ
	sub $s2, $s2, $t0		# padding = 4 - wyliczone modulo
		
allocate_memory: 			# alokuje pamiêæ dla tablicy pikseli
	# najpierw wyliczamy szerokoœæ w bajtach (dla u³atwienia)
	move $t0, $s1			# t0 = width
	mul $t0, $t0, 3			# t0 = width * 3
	add $t0, $t0, $s2		# t0 = width * 3 + padding
	move $s3, $t0			# s3 = width * 3 + padding (nasza szerokoœæ w bajtach, przyda siê póŸniej)
	
	mul $t0, $t0, $s0		# t0 = (width * 3 + padding) * height
	
	li $v0, 9			# alokacja pamiêci
	move $a0, $t0			
	syscall
	
	move $s4, $v0			# s4 = v0 (zapamiêtujemy adres zaalokwanej pamiêci)
	
compute_delta:				# liczymy jak¹ "szerokoœæ" liczbow¹ ma jeden piksel
	move $t0, $s5			
	sll $t0, $t0, 1			# t0 = range * 2                 # mul $t0, $t0, 2
	sll $t0, $t0, 14		# konwersja t0 do Q16.16	 # mo¿na wszystko za³atwiæ tak: sll $t0, $s5, 17 (chyba)
	
	div $t0, $t0, $s1		# t0 = t0 / width (wynik w Q16.16)
	
	move $s6, $t0 		

set_background:
	move $t0, $zero			# t0 - licznik iteruj¹cy po wysokoœci
height_loop:
	move $t1, $zero			# t1 - licznik interuj¹cy po szerokoœci
width_loop:
	move $t3, $zero			# t3 - adres sk³adowej koloru piksela
	mul $t3, $t0, $s3		# t3 = t0 * (width * 3 + padding) 
	mul $t5, $t1, 3			# mo¿na zrobiæ przesuniêciem i sum¹!!!!!!!!!!!!!!!	
	add $t3, $t3, $t5		# t3 = t0 * (width * 3 + padding) + 3 * t1
	
	add $t3, $t3, $s4		# t3 = MEMORY BLOCK + height * (width * 3 + padding) + 3 * t1 (adres efektywny)
	
	li $t4, 0x23			# B
	sb $t4, ($t3)
	
	li $t4, 0x1A			# G
	sb $t4, 1($t3)

	li $t4, 0x21			# R
	sb $t4, 2($t3)

	addi $t1, $t1, 1		# zwiêksz iterator szerokoœci bitmapy
	blt $t1, $s1, width_loop
	addi $t0, $t0, 1		# zwiêksz iterator wysokoœci bitmapy
	beq $t0, $s0, OX_prepare		
	b height_loop

OX_prepare:
	# oœ pozioma
	sra $t0, $s0, 1			# t0 - po³owa wysokoœci
	mul $t1, $t0, $s3		# t1 = po³owa wysokoœci * (szerokoœæ*3 + padding), iterator
	add $t1, $t1, $s4		# t1 - adres efektywny, wartoœæ pocz¹tkowa iteratora
	
	mul $t2, $s1, 3			# t2 - warunek koñcowy
	add $t2, $t2, $t1
	
	li $t3, 0x33			# B
	li $t4, 0x25			# G
	li $t5, 0x30			# R
	
OX_loop	:
	sb $t3, ($t1)			# B
	sb $t4, 1($t1)			# G
	sb $t5, 2($t1)			# R

	add $t1, $t1, 3			# zwiêksz iterator
	blt $t1, $t2, OX_loop

OX_scale:	
	div $t0, $s0, 25		# t0 - jak du¿a podzia³ka
					# jedna kreska podzia³ki bêdzie mia³a 5% rozmiaru obrazka
					
	sll $t1, $s5, 1			# t1 - ile kresek podzia³ki ma byæ na osi 
	#sub $t1, $t1, 1		# (iterator ile kresek zosta³o jeszcze do narysowania)
	
	div $t2, $s1, $t1		# t2 - co ile pikseli ma byæ kreska podzia³ki

	mul $t3, $t2, 3			# t3 - co ile bajtów jest kreska
	
					# t4 - miejsce rysowania (sta³a dla wewnêtrznej pêtli)
	sra $t4, $s0, 1			# po³owa wysokoœci
	mul $t4, $t4, $s3		# ustawiamy siê w odpowiedniej linii
	add $t4, $t4, $s4		# teraz t4 - adres efektywny
	add $t4, $t4, $t3		# ustawiamy siê na miejscu pierwszej kreski
	
	move $t5, $t4			# t5 - kopia t4 (tego bêdziemy u¿ywaæ do przesuwania siê w wewnêtrznej pêtli)
OX_scale_loop:
	
	move $t5, $t4			# t5 - miejsce w bajtach 
	move $t6, $t0			# t6 - ile pikseli kreski zosta³o do narysowania
	# rysuj kreskê (wewnêtrzna pêtla):
	OX_scale_inner_loop:
		add $t5, $t5, $s3
		sub $t6, $t6, 1
		
		# rysuj
		li $t7, 0x33			# B
		sb $t7, ($t5)
	
		li $t7, 0x25			# G
		sb $t7, 1($t5)
		
		li $t7, 0x30			# R
		sb $t7, 2($t5)
		
		bgtz $t6, OX_scale_inner_loop
	
	move $t5, $t4			# t5 - miejsce w bajtach 
	move $t6, $t0			# t6 - ile pikseli kreski zosta³o do narysowania
	# rysuj kreskê (wewnêtrzna pêtla):
	OX_scale_inner_loop2:
		sub $t5, $t5, $s3
		sub $t6, $t6, 1
		
		# rysuj
		li $t7, 0x33			# B
		sb $t7, ($t5)
	
		li $t7, 0x25			# G
		sb $t7, 1($t5)
		
		li $t7, 0x30			# R
		sb $t7, 2($t5)
		
		bgtz $t6, OX_scale_inner_loop2
	
	# koniec wewnêtrznej pêtli
	sub $t1, $t1, 1			# zmniejsz iterator
	add $t4, $t4, $t3 
	bgtz $t1, OX_scale_loop
	
	
OY_prepare:
	# oœ pionowa
	sra $t0, $s1, 1
	mul $t1, $t0, 3
	add $t1, $t1, $s4		# t1 - adres efektywny, wartoœæ pocz¹tkowa iteratora
	
	mul $t2, $s0, $s3
	add $t2, $t2, $t1		# t2 - warunek koñcowy
	
OY_loop	:
	# rysuj rysuj
	li $t3, 0x33			# B
	sb $t3, ($t1)
	
	li $t4, 0x25			# G
	sb $t4, 1($t1)
	
	li $t5, 0x30			# R
	sb $t5, 2($t1)

	add $t1, $t1, $s3		# zwiêksz iterator
	blt $t1, $t2, OY_loop

##############################################################################################################################

OY_scale:	
	div $t0, $s1, 25		# t0 - jak du¿a podzia³ka
					# jedna kreska podzia³ki bêdzie mia³a 5% rozmiaru obrazka
					
	sll $t1, $s5, 1			# t1 - ile kresek podzia³ki ma byæ na osi 
	#sub $t1, $t1, 1		# (iterator ile kresek zosta³o jeszcze do narysowania)
	
	div $t2, $s1, $t1		# t2 - co ile pikseli ma byæ kreska podzia³ki

	mul $t3, $t2, $s3		# t3 - co ile bajtów jest kreska
	
					# t4 - miejsce rysowania (sta³a dla wewnêtrznej pêtli)
	sra $t4, $s1, 1			# po³owa szerokoœci
	mul $t4, $t4, 3			# ustawiamy siê w odpowiedniej linii
	add $t4, $t4, $s4		# teraz t4 - adres efektywny
	add $t4, $t4, $t3		# ustawiamy siê na miejscu pierwszej kreski
	
	move $t5, $t4			# t5 - kopia t4 (tego bêdziemy u¿ywaæ do przesuwania siê w wewnêtrznej pêtli)
OY_scale_loop:
	
	move $t5, $t4			# t5 - miejsce w bajtach 
	move $t6, $t0			# t6 - ile pikseli kreski zosta³o do narysowania
	# rysuj kreskê (wewnêtrzna pêtla):
	OY_scale_inner_loop:
		add $t5, $t5, 3
		sub $t6, $t6, 1
		
		# rysuj
		li $t7, 0x33			# B
		sb $t7, ($t5)
	
		li $t7, 0x25			# G
		sb $t7, 1($t5)
		
		li $t7, 0x30			# R
		sb $t7, 2($t5)
		
		bgtz $t6, OY_scale_inner_loop
	
	move $t5, $t4			# t5 - miejsce w bajtach 
	move $t6, $t0			# t6 - ile pikseli kreski zosta³o do narysowania
	# rysuj kreskê (wewnêtrzna pêtla):
	OY_scale_inner_loop2:
		sub $t5, $t5, 3
		sub $t6, $t6, 1
		
		# rysuj
		li $t7, 0x33			# B
		sb $t7, ($t5)
	
		li $t7, 0x25			# G
		sb $t7, 1($t5)
		
		li $t7, 0x30			# R
		sb $t7, 2($t5)
		
		bgtz $t6, OY_scale_inner_loop2
	
	# koniec wewnêtrznej pêtli
	sub $t1, $t1, 1			# zmniejsz iterator
	add $t4, $t4, $t3 
	bgtz $t1, OY_scale_loop

##############################################################################################################################	
																			
produce_parabola:			# pêtla wyliczaj¹ca wszystkie piksele
	neg $t0, $s5			# t0 = - ZAKRES (Q16.16)
	sll $t0, $t0, 14
	move $t1, $s5			# t1 = + ZAKRES (Q16.16)
	sll $t1, $t1, 14
	
	move $t2, $t0			# t2 - iterator po argumentach (po x), na pocz¹tku t2 = t0

parabola_loop:
	move $a0, $t2			# oblicz wartoœæ i ustaw piksel (je¿eli w zakresie)
	move $a1, $t0
	move $a2, $t1
	jal compute
	
	add $t2, $t2, $s6		# x = x + delta
	blt $t2, $t1, parabola_loop

open_file:
	li $v0, 13			# otwieramy plik
	la $a0, output
	li $a1, 1
	li $a2, 0
	syscall  
	bltz $v0, error			# je¿eli b³¹d otwarcia, to koñczymy program
	
	move $s7, $v0			# zapisujemy sobie deskryptor otwartego pliku
	
prepare_header:				# przygotowujemy nag³ówek (poza "BM")

	################################# BITMAPFILEHEADER
	
	# ca³kowity rozmiar pliku w bajtach
	move $t0, $s3			# liczymy rozmiar pliku
	mul $t0, $t0, $s0
	add $t0, $t0, 54
	sw $t0, header			# rozmiar pliku w bajtach
	
	# sta³e zero
	sh $zero, header + 4
	
	# sta³e zero
	sh $zero, header + 6
	
	# przesuniêcie w bajtach danych obrazu od rekordu BITMAPFILEHEADER
	li $t0, 54
	sw $t0, header + 8
	
	
	################################# BITMAPINFOHEADER	
	
	# rozmiar rekordu BITMAPINFOHEADER
	li $t0, 40
	sw $t0, header + 12
	
	# szerokoœæ obrazu w pikselach
	sw $s1, header + 16
	
	# wydokoœæ obrazu w pikselach
	sw $s0, header + 20
	
	# sta³a jedynka
	li $t0, 1
	sh $t0, header + 24
	
	# iloœæ bitów na piksel
	li $t0, 24
	sh $t0, header + 26
	
	# typ kompresji
	sw $zero, header + 28
	
	# rozmiar mapy bitowej w bajtach
	sw $zero, header + 32
	
	# rozdzielczoœæ poziomowa
	sw $zero, header + 36
	
	# rozdzielczoœæ pionowa
	sw $zero, header + 40

	# liczba elementów tablicy kolorów (0 = max)	
	sw $zero, header + 44
	
	# liczba kolorów wymagana do poprawnego wyœwietlania
	sw $zero, header + 48
									
write_header:				# generujemy nag³ówek bitmapy
	# znaki "BM"
	li $v0, 15
	move $a0, $s7			# podajemy nasz deskryptor jako argument 
	la $a1, bm			# zapisujemy dwa znaki na pocz¹tku bitmapy
	li $a2, 2			# ile bajtów zapisaæ
	syscall
	bltz $v0, error			# je¿eli b³¹d zapisu, to koñczymy program
	
	# reszta nag³ówka
	li $v0, 15
	move $a0, $s7			# podajemy nasz deskryptor jako argument 
	la $a1, header			# zapisujemy dwa znaki na pocz¹tku bitmapy
	li $a2, 52			# ile bajtów zapisaæ
	syscall
	bltz $v0, error			# je¿eli b³¹d zapisu, to koñczymy program
	
write_image:
	# zapisujemy tablicê pikseli (wraz z paddingiem)
	
	move $t0, $s3			# liczymy ile bajtów mamy do zapisania
	mul $t0, $t0, $s0
	
	li $v0, 15
	move $a0, $s7			# podajemy nasz deskryptor jako argument 
	move $a1, $s4			# adres bloku pamiêci z danymi o pikselach
	move $a2, $t0			# liczba zapisywanych bajtów
	syscall
	bltz $v0, error			# je¿eli b³¹d zapisu, to koñczymy program
	
close_file:
	li $v0, 16			# zamykamy plik
	move $a0, $s7
	syscall
	
end:
	li $v0, 10
	syscall
	
error:
	la $a0, text_error
	li $v0, 4
	syscall
	li $v0, 10
	syscall

compute:				# podprocedura licz¹ca wartoœæ funkcji kwadratowej i ustawiaj¹ca kolor piksela
					# a0 - argument funkcji kwadratowej, notacja Q16.16
					# a1 - - ZAKRES (Q16.16)
					# a2 - + zakres (Q16.16)
					
	lw $t3, A			# t3 = A (Q16.16)
	lw $t4, B			# t4 = B (Q16.16)
	lw $t5, C			# t5 = C (Q16.16)
	move $t6, $a0			# t6 - tu bêdzie wartoœæ funkcji
	mul $t6, $t6, $t3		# t6 = x * A
	sra $t6, $t6, 14
	
	add $t6, $t6, $t4		# t6 = x * A + B
	mul $t6, $t6, $a0		# t6 = (x * A + B) * x
	sra $t6, $t6, 14
	
	add $t6, $t6, $t5		# t6 = (x * A + B) * x + C
	
	blt $t6, $a1, return		# jeœli poza zakresem, to wyjdŸ
	bgt $t6, $a2, return		# jeœli poza zakresem, to wyjdŸ
	
	add $a0, $a0, $a2		# œrodek uk³adu ma byæ w œrodku obrazka, dodajemy + ZAKRES
	add $t6, $t6, $a2		# œrodek uk³adu ma byæ w œrodku obrazka, dodajemy + ZAKRES
	
	div $a0, $a0, $s6		# dzielimy przez deltê
	sll $a0, $a0, 14

	
	div $t6, $t6, $s6
	sll $t6, $t6, 14
	
	sra $a0, $a0, 14
	sra $t6, $t6, 14		# teraz mamy wynik w pikselach 
	
	
	
	#sub $t6, $s0, $t6 		# uwzglêdniamy odwrócenie pionowe formatu bmp
					# teraz w t6 mamy numer linii w tablicy pikseli
	mul $t6, $t6, $s3			
	mul $t7, $a0, 3
	
	add $t7, $t6, $t7
	add $t7, $t7, $s4		# adres efektywny
	
	# t7 - adres efektywny
	
	li $t3, 0xF9			# B
	sb $t3, ($t7)
	
	li $t4, 0xF9			# G
	sb $t4, 1($t7)
	
	li $t5, 0xF9			# R
	sb $t5, 2($t7)
	
return:
	jr $ra

# to na razie nie jest potrzebne:

