# Projekt 1 MIPS
# Rysowanie paraboli w uk�adzie wsp�rz�dnych

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

bm:			.ascii "BM"	# dwa znaki informuj�ce, �e to jest bitmapa
.align 2		# wyr�wnaj do 4 bajt�w
header:			.space 52	# nag��wek bitmapy

# coefficients
.align 2		# wyr�wnaj do 4 bajt�w
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
# s6 - delta x (szeroko�� liczbowa piksela, zapisane w Q16.16)
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
	
	move $s0, $v0 			# wczytaj do $s0 wysoko�� obrazka
	
get_width: 				# czyta szerokosc obrazka
	li $v0, 4
	la $a0, text_width_prompt
	syscall
	
	li $v0, 5
	syscall
	
	move $s1, $v0 			# wczytaj do $s1 szeroko�� obrazka (bez paddingu)
	
get_range: 				# czyta zakres skali
	li $v0, 4
	la $a0, text_range_prompt
	syscall
	
	li $v0, 5
	syscall
	
	move $s5, $v0 			# wczytaj do $s1 szeroko�� obrazka (bez paddingu)
	
compute_padding:
	move $t0, $s1
	mul $t0, $t0, 3			# reszta z dzielenia szerokosci*3 przez 4 
	andi $t0, $t0, 3		# do $t0 �aduje warto�� (szeroko��*3) MOD 4
	
	li $s2, 0			# domy�lnie zerowy padding
	beqz $t0, allocate_memory	# wyliczone modulo = 0, padding r�wny zero, skaczemy do nast�pnego fragmentu programu
	
	li $s2, 4			# je�li modulo > 0, liczymy ile bajt�w paddingu trzeba doda�
	sub $s2, $s2, $t0		# padding = 4 - wyliczone modulo
		
allocate_memory: 			# alokuje pami�� dla tablicy pikseli
	# najpierw wyliczamy szeroko�� w bajtach (dla u�atwienia)
	move $t0, $s1			# t0 = width
	mul $t0, $t0, 3			# t0 = width * 3
	add $t0, $t0, $s2		# t0 = width * 3 + padding
	move $s3, $t0			# s3 = width * 3 + padding (nasza szeroko�� w bajtach, przyda si� p�niej)
	
	mul $t0, $t0, $s0		# t0 = (width * 3 + padding) * height
	
	li $v0, 9			# alokacja pami�ci
	move $a0, $t0			
	syscall
	
	move $s4, $v0			# s4 = v0 (zapami�tujemy adres zaalokwanej pami�ci)
	
compute_delta_x:			# liczymy jak� "szeroko��" liczbow� ma jeden piksel
	move $t0, $s5
	mul $t0, $t0, 2			# t0 = range * 2
	sll $t0, $t0, 16		# konwersja t0 do Q16.16
	div $t0, $t0, $s1		# t0 = t0 / width (wynik w Q16.16)
	
	move $s6, $t0 		

set_background:
	move $t0, $zero			# t0 - licznik iteruj�cy po wysoko�ci
height_loop:
	move $t1, $zero			# t1 - licznik interuj�cy po szeroko�ci
width_loop:
	move $t3, $zero			# t3 - adres sk�adowej koloru piksela
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


	addi $t1, $t1, 1		# zwi�ksz iterator szeroko�ci bitmapy
	blt $t1, $s1, width_loop
	addi $t0, $t0, 1		# zwi�ksz iterator wysoko�ci bitmapy
	beq $t0, $s0, produce_parabola		
	b height_loop
	
produce_parabola:			# p�tla wyliczaj�ca wszystkie piksele
	# liczymy, liczymy, liczymy...

produce_scale:
	# liczymy, liczymy, liczymy...

open_file:
	li $v0, 13			# otwieramy plik
	la $a0, output
	li $a1, 1
	li $a2, 0
	syscall  
	bltz $v0, error			# je�eli b��d otwarcia, to ko�czymy program
	
	move $s7, $v0			# zapisujemy sobie deskryptor otwartego pliku
	
prepare_header:				# przygotowujemy nag��wek (poza "BM")

	################################# BITMAPFILEHEADER
	
	# ca�kowity rozmiar pliku w bajtach
	move $t0, $s3			# liczymy rozmiar pliku
	mul $t0, $t0, $s0
	add $t0, $t0, 54
	sw $t0, header			# rozmiar pliku w bajtach
	
	# sta�e zero
	sh $zero, header + 4
	
	# sta�e zero
	sh $zero, header + 6
	
	# przesuni�cie w bajtach danych obrazu od rekordu BITMAPFILEHEADER
	li $t0, 54
	sw $t0, header + 8
	
	
	################################# BITMAPINFOHEADER	
	
	# rozmiar rekordu BITMAPINFOHEADER
	li $t0, 40
	sw $t0, header + 12
	
	# szeroko�� obrazu w pikselach
	sw $s1, header + 16
	
	# wydoko�� obrazu w pikselach
	sw $s0, header + 20
	
	# sta�a jedynka
	li $t0, 1
	sh $t0, header + 24
	
	# ilo�� bit�w na piksel
	li $t0, 24
	sh $t0, header + 26
	
	# typ kompresji
	sw $zero, header + 28
	
	# rozmiar mapy bitowej w bajtach
	sw $zero, header + 32
	
	# rozdzielczo�� poziomowa
	sw $zero, header + 36
	
	# rozdzielczo�� pionowa
	sw $zero, header + 40

	# liczba element�w tablicy kolor�w (0 = max)	
	sw $zero, header + 44
	
	# liczba kolor�w wymagana do poprawnego wy�wietlania
	sw $zero, header + 48
									
write_header:				# generujemy nag��wek bitmapy
	# znaki "BM"
	li $v0, 15
	move $a0, $s7			# podajemy nasz deskryptor jako argument 
	la $a1, bm			# zapisujemy dwa znaki na pocz�tku bitmapy
	li $a2, 2			# ile bajt�w zapisa�
	syscall
	bltz $v0, error			# je�eli b��d zapisu, to ko�czymy program
	
	# reszta nag��wka
	li $v0, 15
	move $a0, $s7			# podajemy nasz deskryptor jako argument 
	la $a1, header			# zapisujemy dwa znaki na pocz�tku bitmapy
	li $a2, 52			# ile bajt�w zapisa�
	syscall
	bltz $v0, error			# je�eli b��d zapisu, to ko�czymy program
	
write_image:
	# zapisujemy tablic� pikseli (wraz z paddingiem)
	
	move $t0, $s3			# liczymy ile bajt�w mamy do zapisania
	mul $t0, $t0, $s0
	
	li $v0, 15
	move $a0, $s7			# podajemy nasz deskryptor jako argument 
	move $a1, $s4			# adres bloku pami�ci z danymi o pikselach
	move $a2, $t0			# liczba zapisywanych bajt�w
	syscall
	bltz $v0, error			# je�eli b��d zapisu, to ko�czymy program
	
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
	
quadratic:				# podprocedura licz�ca warto�� funkcji kwadratowej i ustawiaj�ca kolor piksela
					# a0 - argument funkcji kwadratowej, notacja Q16.16
	# TODO
	jr $ra	

