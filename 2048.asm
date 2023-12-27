.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern memcpy: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Proiect 2048 Dinca Diana",0
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

d16 DD 16
d10 DD 10
n EQU 4 	;matricea are 4 linii si 4 coloane
matrix_x DD 240, 290, 340, 390
		 DD 240, 290, 340, 390
		 DD 240, 290, 340, 390
		 DD 240, 290, 340, 390
		 
matrix_y DD 115, 115, 115, 115
		 DD 165, 165, 165, 165
		 DD 215, 215, 215, 215
		 DD 265, 265, 265, 265
		 
matrix_aux 	DD 0, 0, 0, 0 
			DD 0, 0, 0, 0
			DD 0, 0, 0, 0
			DD 0, 0, 0, 0
			
matrix_combinari DD 0, 0, 0, 0 
				 DD 0, 0, 0, 0
				 DD 0, 0, 0, 0
				 DD 0, 0, 0, 0		
	
matrix 	DD 0, 0, 0, 0 ;matrice-- LUCRAM AICI 
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
		
matrixB	DD 0, 0, 0, 0 ;matrice B-- BACK 1
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
matrixC DD 0, 0, 0, 0 ;matrice C-- BACK 2
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
matrixD DD 0, 0, 0, 0 ;matrice D-- BACK 3
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
matrixE DD 0, 0, 0, 0 ;matrice E-- BACK 4
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
matrixF DD 0, 0, 0, 0 ;matrice F-- BACK 5
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0
		DD 0, 0, 0, 0

off DB 0
number  DB 0
four DD 4

culoare DD 0

poz DD 4 
poz2 DD 11
scor DD 0
scorB DD 0
scorC DD 0
scorD DD 0
scorE DD 0
scorF DD 0
contor DD 0

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov EDX, culoare
	mov dword ptr [edi], EDX
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0ffffffh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

line_orizontala MACRO x,y,len,color
local bucla_linie
	mov eax, y
	mov ebx, area_width
	mul ebx 
	add eax, x 
	shl eax, 2         
	add eax, area
	mov ecx, len
	bucla_linie:
		mov dword ptr[eax], color;
		add eax, 4
	loop bucla_linie
ENDM

line_verticala MACRO x,y,len,color
local bucla_linie
	mov eax, y
	mov ebx, area_width
	mul ebx 
	add eax, x 
	shl eax, 2         
	add eax, area
	mov ecx, len
	bucla_linie:
		mov dword ptr[eax], color;
		add eax, area_width*4
	loop bucla_linie
ENDM

generare_random proc
	rdtsc 		;generez un nr random
	mov EDX,0
	div d16		;%16 pentru a afla pozitia din matrice
	mov ECX,EDX	;retin in ECX

	mov EAX,0
	mov EDX,0
	rdtsc 
	mov EDX,0	
	div d10		;%10 pentu a primi valoarea 2 sau 4
	
	cmp EDX, 5
	ja patric	;daca e <
	mov EBX, 2  ;retin in EBX 
	jmp returnare
	patric:
	mov EBX, 4	;daca e >
	returnare:
	ret
generare_random endp

plasare_matrice proc
	call generare_random
	mov EDX, ECX
	mov ECX, 16
	salt:
		cmp EDX, 16
		je reluare
		
		cmp matrix[EDX*4],0	;verific daca e pozitia libera
		je gasit
		inc EDX
		jmp next
		
		reluare:
		mov EDX, 0
		
		next:
	loop salt
	
	jmp nu_gasit
	
	gasit:
	mov matrix[EDX*4],EBX
	jmp finish
	
	nu_gasit:
	make_text_macro 'E', area, 290, 350
	make_text_macro 'N', area, 300, 350
	make_text_macro 'D', area, 310, 350
	
	make_text_macro 'G', area, 330, 350
	make_text_macro 'A', area, 340, 350
	make_text_macro 'M', area, 350, 350
	make_text_macro 'E', area, 360, 350
	
	finish:
	
	ret
plasare_matrice endp


afisare proc
	mov ECX, 0	
	;for(i=0; i<=15; i++)
	continua_for:
	cmp ECX, 15
	ja iesire_for
		;zero:
			mov EAX, 0 
			mov EAX, matrix_x[ecx*4]
			sub EAX, 15
			make_text_macro ' ', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro ' ', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro ' ', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro ' ', area, eax,  matrix_y[ecx*4]	
			
		cmp matrix[ECX*4], 0
		je next
		cmp matrix[ECX*4], 4
		je patru
		cmp matrix[ECX*4], 8
		je opt
		cmp matrix[ECX*4], 16
		je unusase
		cmp matrix[ECX*4], 32
		je treidoi
		cmp matrix[ECX*4], 64
		je sasepatru
		cmp matrix[ECX*4], 128
		je unudoiopt
		cmp matrix[ECX*4], 256
		je doicincisase
		cmp matrix[ECX*4], 512
		je cinciunudoi
		cmp matrix[ECX*4], 1024
		je unuzerodoipatru
		cmp matrix[ECX*4], 2048
		je doizeropatruopt
		
			mov culoare, 0e8e337h			
			make_text_macro '2', area, matrix_x[ecx*4],  matrix_y[ecx*4]
			jmp next
		patru:
			mov culoare, 0e6cc00h
			make_text_macro '4', area, matrix_x[ecx*4],  matrix_y[ecx*4]
			jmp next
		opt:
			mov culoare, 0e69b00h
			make_text_macro '8', area, matrix_x[ecx*4],  matrix_y[ecx*4]
			jmp next
		unusase:
			mov culoare, 0ff7b7bh
			mov EAX, 0 
			mov EAX, matrix_x[ecx*4]
			sub EAX, 5
			make_text_macro '1', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '6', area, eax,  matrix_y[ecx*4]
			jmp next
		treidoi:
			mov culoare, 0ff0000h
			mov EAX, 0 
			mov EAX, matrix_x[ecx*4]
			sub EAX, 5
			make_text_macro '3', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '2', area, eax,  matrix_y[ecx*4]
			jmp next
		sasepatru:
			mov culoare, 0a70000h
			mov EAX, 0 
			mov EAX, matrix_x[ecx*4]
			sub EAX, 5
			make_text_macro '6', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '4', area, eax,  matrix_y[ecx*4]
			jmp next
		unudoiopt:
			mov culoare, 076bd85h
			mov EAX, 0 
			mov EAX, matrix_x[ecx*4]
			sub EAX, 10
			make_text_macro '1', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '2', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '8', area, eax,  matrix_y[ecx*4]
			jmp next
		doicincisase:
			mov culoare, 0718138h
			mov EAX, 0 
			mov EAX, matrix_x[ecx*4]
			sub EAX, 10
			make_text_macro '2', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '5', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '6', area, eax,  matrix_y[ecx*4]
			jmp next
		cinciunudoi:
			mov culoare, 367738h
			mov EAX, 0 
			mov EAX, matrix_x[ecx*4]
			sub EAX, 10
			make_text_macro '5', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '1', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '2', area, eax,  matrix_y[ecx*4]
			jmp next
		unuzerodoipatru:
			mov culoare, 0FF87EDh
			mov EAX, 0 
			mov EAX, matrix_x[ecx*4]
			sub EAX, 15
			make_text_macro '1', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '0', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '2', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '4', area, eax,  matrix_y[ecx*4]
			jmp next
		doizeropatruopt:
			mov culoare, 0D301B4h
			mov EAX, 0 
			mov EAX, matrix_x[ecx*4]
			sub EAX, 15
			make_text_macro '2', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '0', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '4', area, eax,  matrix_y[ecx*4]
			add EAX, 10
			make_text_macro '8', area, eax,  matrix_y[ecx*4]
			jmp next
			
		next:
	inc ECX
	jmp continua_for
	iesire_for:
	ret
afisare endp

copiere_undo proc
	mov ECX, 0
	mov EAX, 0
	
	bucla:
		cmp ECX, 15
		ja end_bucla
		
		mov EAX, matrix[ECX*4]
		mov EBX, 16
		add EBX, ECX
		mov matrix[EBX*4], EAX
	
		inc ECX
		jmp bucla
	end_bucla:
	ret
copiere_undo endp

golire macro A
local bucla, end_bucla
	; memset(A, 0, 64)
	mov ECX, 0
	bucla:
		cmp ECX, 15
		ja end_bucla
		
		mov A[ECX*4], 0
		
		inc ECX		
		jmp bucla 
	end_bucla:
endm

;directiile de mutare ale elementelor
;avem poz=4 pozitia din 'matrice'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		SUS
sageata_sus proc
	golire matrix_combinari
	mov EAX, 0
	mov EBX, 0
	mov EDX, 0
	mov EDI, 0
	mov ECX, poz	
	
	;for(i=4; i<=15; i++)
	continua_for1:
		cmp ECX, 15
		ja iesire_for1
		
		mov EDI, ECX
		mov ESI, 0
		;for(j=ECX, j>=0; j-4)
		continua_for2:
		cmp EDI, 0
		jbe iesire_for2
		cmp EDI, 1
		je iesire_for2
		cmp EDI, 2
		je iesire_for2
		cmp EDI, 3
		je iesire_for2
			mov EAX, EDI
			sub EAX, poz			;pozitita de deasupra elementului matrix[ECX*4]
			
			mov EDX, matrix[EDI*4]
			cmp EDX, 0				;daca avem 0 nu facem nimic
			je iesire_for2
			
			cmp matrix[EAX*4], 0	;daca avem casuta goala se permite adunarea(mutarea cu o pozitie in sus)
			je combin
			
			cmp matrix_combinari[EAX*4], 1  ;daca s-a facut deja o combinare pe pozitia asta sar 
			je iesire_for2
		
			cmp EDX,matrix[EAX*4]	;daca sunt egale le adun
			jne iesire_for2			;nu sunt egale sar
			inc ESI					;daca sunt egale contorul e 1, pt ca efectueaza deja o adunare
			mov matrix_combinari[EAX*4], 1
			add scor, EDX			;adun la scor
			add scor, EDX			;adun la scor
			
			combin:
			cmp ESI, 1
			ja iesire_for2
			mov EBX, matrix[EDI*4]
			add EBX, matrix[EAX*4]	;adun matrix[ECX*4] pe pozitia matrix[(ECX-4)*4] 
			mov matrix[EAX*4], EBX
			mov EBX, 0
			mov matrix[EDI*4], EBX	;pun 0 pe pozitia matrix[ECX*4]
		
		sub EDI, 4
		jmp continua_for2
		iesire_for2:
		
	inc ECX
	jmp continua_for1
	iesire_for1:
	ret
sageata_sus endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		JOS
sageata_jos proc
	golire matrix_combinari
	mov EAX, 0
	mov EBX, 0
	mov EDX, 0
	mov EDI, 0
	mov ECX, poz2
	
	;for(i=11; i>=0; i--)
	continua_for1:
		cmp ECX, 0ffffffffh
		je iesire_for1
		
		mov EDI, ECX
		mov ESI, 0
		;for(j=ECX; j<=15; j+4)
		continua_for2:
		cmp EDI, 15
		jae iesire_for2
		
			mov EAX, EDI
			add EAX, poz			;pozitita de sub elementul matrix[ECX*4]
			
			cmp EAX, 15
			ja iesire_for2
			
			mov EDX, matrix[EDI*4]
			cmp EDX, 0				;daca avem 0 nu facem nimic
			je iesire_for2
			
			cmp matrix[EAX*4], 0	;daca avem casuta goala se permite adunarea(mutarea cu o pozitie in sus)
			je combin	
			
			cmp matrix_combinari[EAX*4], 1  ;daca s-a facut deja o combinare pe pozitia asta sar 
			je iesire_for2
			
			cmp EDX,matrix[EAX*4]	;daca nu sunt egale nu le adun
			jne iesire_for2
			inc ESI					;daca sunt egale contorul e 1, pt ca efectueaza deja o adunare
			mov matrix_combinari[EAX*4], 1
			add scor, EDX			;adun la scor
			add scor, EDX			;adun la scor
			
			combin:
			cmp ESI, 1
			ja iesire_for2 
			mov EBX, matrix[EDI*4]
			add EBX, matrix[EAX*4]	;adun matrix[ECX*4] pe pozitia matrix[(ECX-4)*4] 
			mov matrix[EAX*4], EBX
			mov EBX, 0
			mov matrix[EDI*4], EBX	;pun 0 pe pozitia matrix[ECX*4]
			
			
		add EDI, 4
		jmp continua_for2
		iesire_for2:
		
	dec ECX
	jmp continua_for1
	iesire_for1:
	ret
sageata_jos endp

copymatrix macro A, B
local bucla, end_bucla
	mov ECX, 0
	mov EAX, 0
	bucla:
		cmp ECX, 15
		ja end_bucla
		mov EAX, A[ECX*4]
		mov B[ECX*4], EAX
		inc ECX
		jmp bucla
	end_bucla:
endm

rotire proc
	mov EAX, 0
	mov EBX, 0
	;;;rotesc matricea initiala la stanga astfel incat pozitiile vor fi
	;;;pozitia 0 ajunge pe 12
		mov EAX, matrix[0]
		mov	matrix_aux[12*4], EAX
		
	;;;pozitia 1 ajunge pe 8
		mov EAX, matrix[1*4]
		mov	matrix_aux[8*4], EAX

	;;;pozitia 2 ajunge pe 4
		mov EAX, matrix[2*4]
		mov	matrix_aux[4*4], EAX

	;;;pozitia 3 ajunge pe 0
		mov EAX, matrix[3*4]
		mov	matrix_aux[0], EAX

	;;;pozitia 4 ajunge pe 13
		mov EAX, matrix[4*4]
		mov	matrix_aux[13*4], EAX
				
	;;;pozitia 5 ajunge pe 9
		mov EAX, matrix[5*4]
		mov	matrix_aux[9*4], EAX
		
	;;;pozitia 6 ajunge pe 5
		mov EAX, matrix[6*4]
		mov	matrix_aux[5*4], EAX
		
	;;;pozitia 7 ajunge pe 1
		mov EAX, matrix[7*4]
		mov	matrix_aux[1*4], EAX
		
	;;;pozitia 8 ajunge pe 14
		mov EAX, matrix[8*4]
		mov	matrix_aux[14*4], EAX

	;;;pozitia 9 ajunge pe 10
		mov EAX, matrix[9*4]
		mov	matrix_aux[10*4], EAX
		
	;;;pozitia 10 ajunge pe 6
		mov EAX, matrix[10*4]
		mov	matrix_aux[6*4], EAX
	
	;;;pozitia 11 ajunge pe 2
		mov EAX, matrix[11*4]
		mov	matrix_aux[2*4], EAX
	
	;;;pozitia 12 ajunge pe 15
		mov EAX, matrix[12*4]
		mov	matrix_aux[15*4], EAX
		
	;;;pozitia 13 ajunge pe 11
		mov EAX, matrix[13*4]
		mov	matrix_aux[11*4], EAX	
				
	;;;pozitia 14 ajunge pe 7
		mov EAX, matrix[14*4]
		mov	matrix_aux[7*4], EAX
		
	;;;pozitia 15 ajunge pe 3
		mov EAX, matrix[15*4]
		mov	matrix_aux[3*4], EAX
		
	copymatrix matrix_aux, matrix;copiez pe aux in matricea initiala
	ret
rotire endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		DREAPTA
sageata_dreapta proc
	call rotire
	call sageata_sus
	call rotire
	call rotire
	call rotire
	ret
sageata_dreapta endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		STANGA
sageata_stanga proc
	call rotire
	call sageata_jos
	call rotire
	call rotire
	call rotire
	ret
sageata_stanga endp

undo proc
	copymatrix matrixE, matrixF
	mov EBX, scorE
	mov scorF, EBX
	copymatrix matrixD, matrixE
	mov EBX, scorD
	mov scorE, EBX
	copymatrix matrixC, matrixD
	mov EBX, scorC
	mov scorD, EBX
	copymatrix matrixB, matrixC
	mov EBX, scorB
	mov scorC, EBX
	copymatrix matrix, matrixB
	mov EBX, scor
	mov scorB, EBX
	ret
undo endp

back proc
	copymatrix matrixB, matrix
	mov EBX, scorB
	mov scor, EBX
	copymatrix matrixC, matrixB
	mov EBX, scorC
	mov scorB, EBX
	copymatrix matrixD, matrixC
	mov EBX, scorD
	mov scorC, EBX
	copymatrix matrixE, matrixD
	mov EBX, scorE
	mov scorD, EBX
	copymatrix matrixF, matrixE
	mov EBX, scorF
	mov scorE, EBX
	ret
back endp

restart proc
	golire matrix
	golire matrixB
	golire matrixC
	golire matrixD
	golire matrixE
	golire matrixF

	mov scor, 0
	mov scorB, 0
	mov scorC, 0
	mov scorD, 0
	mov scorE, 0
	mov scorF, 0
	
	call plasare_matrice
	call plasare_matrice
	;in cazul in care se da meci nou sa nu se poata da back la o matrice goala
	copymatrix matrix, matrixB
	copymatrix matrix, matrixc
	copymatrix matrix, matrixD
	copymatrix matrix, matrixE
	copymatrix matrix, matrixF

	ret
restart endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		AFISARE SCOR
afisare_scor proc
	mov ECX, 6
	mov EBX, 80
	mov EAX, scor
	mov culoare, 000000
	bucla:
		mov EDX, 0
		
		div d10
		add edx, '0'
		
		make_text_macro edx, area, EBX, 100
		
		sub EBX, 10
		
	loop bucla
	ret
afisare_scor endp


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 3
	jz evt_tasta
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12

	jmp afisare_litere
	
evt_tasta:
	call undo
	
	mov EAX,[EBP+arg2] 
	cmp EAX, '&'
	je sus
	cmp EAX, '('
	je jos
	cmp EAX, "'"
	je dreapta
	cmp EAX, '%'
	je stanga
	jmp nexxt
	
	sus:
		call sageata_sus
		jmp next
	jos:
		call sageata_jos
		jmp next
	dreapta:
		call sageata_dreapta
		jmp next
	stanga: 
		call sageata_stanga
		jmp next
		
	next:
	call plasare_matrice
	nexxt:
evt_timer:
	inc counter
	
evt_click:
	;se da click in butonul BACK
	mov EAX, [EBP+arg2]
	cmp EAX, 40
	jl fail
	cmp EAX, 100
	jg fail
	
	mov EAX, [EBP+arg3]
	cmp EAX, 275
	jl fail
	cmp EAX, 305
	jg fail
	
	dec counter
	call back
	make_text_macro ' ', area, 290, 350
	make_text_macro ' ', area, 300, 350
	make_text_macro ' ', area, 310, 350
	
	make_text_macro ' ', area, 330, 350
	make_text_macro ' ', area, 340, 350
	make_text_macro ' ', area, 350, 350
	make_text_macro ' ', area, 360, 350
	fail:

	;se da click in butonul RESTART
	mov EAX, [EBP+arg2]
	cmp EAX, 20
	jl fail2
	cmp EAX, 100
	jg fail2
	
	mov EAX, [EBP+arg3]
	cmp EAX, 225
	jl fail2
	cmp EAX, 275
	jg fail2
	
	call restart
	mov counter, 0
	make_text_macro ' ', area, 290, 350
	make_text_macro ' ', area, 300, 350
	make_text_macro ' ', area, 310, 350
	
	make_text_macro ' ', area, 330, 350
	make_text_macro ' ', area, 340, 350
	make_text_macro ' ', area, 350, 350
	make_text_macro ' ', area, 360, 350
	fail2:
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	;scriem numele jocului
	mov culoare, 000000
	make_text_macro '2', area, 300, 70
	make_text_macro '0', area, 310, 70
	make_text_macro '4', area, 320, 70
	make_text_macro '8', area, 330, 70
	
	make_text_macro 'S', area, 50, 70
	make_text_macro 'C', area, 60, 70
	make_text_macro 'O', area, 70, 70
	make_text_macro 'R', area, 80, 70
	line_orizontala 50, 90, 40, 0bbada0h
	
	make_text_macro 'R', area, 25, 230
	make_text_macro 'E', area, 35, 230
	make_text_macro 'S', area, 45, 230
	make_text_macro 'T', area, 55, 230
	make_text_macro 'A', area, 65, 230
	make_text_macro 'R', area, 75, 230
	make_text_macro 'T', area, 85, 230
	line_orizontala 20, 225, 80, 0bbada0h
	line_orizontala 20, 255, 80, 0bbada0h
	line_verticala 20, 225, 30, 0bbada0h
	line_verticala 100, 225, 30, 0bbada0h
	
	make_text_macro 'B', area, 50, 280
	make_text_macro 'A', area, 60, 280
	make_text_macro 'C', area, 70, 280
	make_text_macro 'K', area, 80, 280
	line_orizontala 40, 275, 60, 0bbada0h
	line_orizontala 40, 305, 60, 0bbada0h
	line_verticala 40, 275, 30, 0bbada0h
	line_verticala 100, 275, 30, 0bbada0h

	
	;desenam tabla de joc
	;dimensiune patrat= 50 
;;;;;linii orizontale
	line_orizontala 220, 100, 200, 0bbada0h
	line_orizontala 220, 150, 200, 0bbada0h
	line_orizontala 220, 200, 200, 0bbada0h
	line_orizontala 220, 250, 200, 0bbada0h
	line_orizontala 220, 300, 200, 0bbada0h
;;;;;linii verticale
	line_verticala 220, 100, 200, 0bbada0h
	line_verticala 270, 100, 200, 0bbada0h
	line_verticala 320, 100, 200, 0bbada0h
	line_verticala 370, 100, 200, 0bbada0h
	line_verticala 420, 100, 200, 0bbada0h

	call afisare
	call afisare_scor
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;la inceput de joc plasam doua valori random in matrice
	;mov culoare, 000000
	call plasare_matrice
	call plasare_matrice
	;in cazul in care se da meci nou sa nu se poata da back la o matrice goala
	copymatrix matrix, matrixB
	copymatrix matrix, matrixc
	copymatrix matrix, matrixD
	copymatrix matrix, matrixE
	copymatrix matrix, matrixF	
	
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax

	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
