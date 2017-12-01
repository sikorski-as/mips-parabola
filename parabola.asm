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
.align 2		# wyrównaj do 4 bajtów
header:			.space 52	# nag³ówek bitmapy

# coefficients
.align 2		# wyrównaj do 4 bajtów
A:			.space 4
B:			.space 4
C:			.space 4
# colors
color_background:	.space 4
color_scale:		.space 4
color_parabola:		.space 4

# s0 - height (px)
# s1 - width (px)
# s2 - padding (bajty)
# s3 - width*3 + padding
# s4 - pointer of allocated memory for the bitmap
# s5 - range	--->	X <-s5, +s5>, Y <-s5, +s5>
# s6 - delta x (szerokoœæ liczbowa piksela, zapisane w Q16.16)
# s7 - deskryptor pliku

.globl main
.text
main:
	li $v0, 4
	la $a0, text_title
	syscall

load_coefficients:
	li $t2, 1
	sw $t2, A
	
	li $t1, 2
	sw $t1, B
	
	li $t0, 1
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
	
	move $s5, $v0 			# wczytaj do $s1 szerokoœæ obrazka (bez paddingu)
	
compute_padding:
	move $t0, $s1
	mul $t0, $t0, 3			# reszta z dzielenia szerokosci*3 przez 4 
	andi $t0, $t0, 3		# do $t0 ³aduje wartoœæ (szerokoœæ*3) MOD 4
	
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
	
compute_delta_x:			# liczymy jak¹ "szerokoœæ" liczbow¹ ma jeden piksel
	move $t0, $s5
	mul $t0, $t0, 2			# t0 = range * 2
	sll $t0, $t0, 16		# konwersja t0 do Q16.16
	div $t0, $t0, $s1		# t0 = t0 / width (wynik w Q16.16)
	
	move $s6, $t0 		

set_background:
	move $t0, $zero			# t0 - licznik iteruj¹cy po wysokoœci
height_loop:
	move $t1, $zero			# t1 - licznik interuj¹cy po szerokoœci
width_loop:
	move $t3, $zero			# t3 - adres sk³adowej koloru piksela
	mul $t3, $t0, $s3		# t3 = t0 * (width * 3 + padding) 
	mul $t5, $t1, 3	
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
	beq $t0, $s0, produce_parabola		
	b height_loop
	
produce_parabola:			# pêtla wyliczaj¹ca wszystkie piksele
	# liczymy, liczymy, liczymy...

produce_scale:
	# liczymy, liczymy, liczymy...

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
	
quadratic:				# podprocedura licz¹ca wartoœæ funkcji kwadratowej i ustawiaj¹ca kolor piksela
					# a0 - argument funkcji kwadratowej, notacja Q16.16
	# TODO
	jr $ra	

