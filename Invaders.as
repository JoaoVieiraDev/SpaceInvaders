;===============================================================================
; PROGRAMA INVADERS.AS
;
;AUTORES: João Vieira
;Ultima alteração: 27/5/2016 (comentários)
;Ultima alteração funcional: 25/5/2016
;===============================================================================
;===============================================================================
; ZONA I: Definicao de constantes
;         Pseudo-instrucao : EQU
;===============================================================================
;
; TEMPORIZACAO
DELAYVALUE      EQU     F000h

; STACK POINTER
SP_INICIAL      EQU     FDFFh

; I/O a partir de FF00H
IO_CURSOR       EQU     FFFCh
IO_STAT		EQU	FFFDh
IO_WRITE        EQU     FFFEh
IO_READ		EQU	FFFFh


; Interrupções
Int_0		EQU     FE00h
TAB_INTTemp     EQU     FE0Fh
INT_A		EQU	FE0AH
INT_B		EQU	FE0BH

INT_7		EQU	FFF9h


;Variaveis Globais
Mover_Aliens	EQU	FC00h
SentidoMov	EQU	FC01h
XY_Alien	EQU	FC02h
Start		EQU	FC03h
TEMPO		EQU	FC04H
TTOTAL		EQU	FC05H
PAUSA		EQU	FC06H
PONTOS		EQU	FC07H
Victory		EQU	FC08h
Defeat		EQU	FC09h
RAPIDO		EQU	FC0AH
RESTART		EQU	FC0BH

;MATRIX
MATRIX		EQU	FD00h
MATRIX_POS	EQU	FD3Bh	

LIMPAR_JANELA   EQU     FFFFh
XY_INICIAL      EQU     0000h
FIM_TEXTO       EQU     '@'

; TEMPORIZADOR
Temp_Aliens	EQU	FFF6h
TempControlo	EQU	FFF7h
MASCARA_INT	EQU	FFFAh

;display
DISP7S1         EQU     FFF0h
DISP7S2         EQU     FFF1h
DISP7S3         EQU     FFF2h
DISP7S4		EQU	FFF3h

LEDS		EQU	FFF8H
LCD_WRITE	EQU	FFF5H
LCD_CURSOR	EQU 	FFF4H
;===============================================================================
; ZONA II: Definicao de variaveis
;          Pseudo-instrucoes : WORD - palavra (16 bits)
;                              STR  - sequencia de caracteres.
;          Cada caracter ocupa 1 palavra
;===============================================================================

                ORIG    8000h
VarTexto1       STR     '|------------------------------------------------------------------------------|',FIM_TEXTO
VarTexto2	STR	'|                                                                              |',FIM_TEXTO
VarTexto3	STR	'     ',FIM_TEXTO
VarNave		STR	'O-^-O',FIM_TEXTO
Var_Alien	STR	'OVO',FIM_TEXTO
Var_Alien0	STR	'   ',FIM_TEXTO
VarLazer	STR	'*',FIM_TEXTO
VarLazer0	STR	' ',FIM_TEXTO
VarIniciar	STR	'Press IO to start',FIM_TEXTO
Var_Victory	STR	'VICTORY!',FIM_TEXTO
Var_Defeat	STR	'DEFEAT!',FIM_TEXTO
CURSOR_POSITION WORD	1526h ;CURSOR_POSITION
VarPONTUACAO	STR	'PONTUACAO',FIM_TEXTO
VarReinicar	STR	'Press IO to restart',FIM_TEXTO

;===============================================================================
; ZONA III: Codigo
;           conjunto de instrucoes Assembly, ordenadas de forma a realizar
;           as funcoes pretendidas
;===============================================================================
                ORIG    0000h
                JMP     inicio

;===============================================================================
; LimpaJanela: Rotina que limpa a janela de texto.
;               Entradas: --
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

LimpaJanela:    PUSH    R2
                MOV     R2, LIMPAR_JANELA
		MOV     M[IO_CURSOR], R2
                POP     R2
                RET

;===============================================================================
; EspJogo: Rotina que efectua a escrita do espaço de jogo na janela de texto.
;===============================================================================

EspJogo:	PUSH 	R6
		PUSH 	R7
                MOV	R6, XY_INICIAL		; Primeira posição da janela
                PUSH    VarTexto1          	; Passagem de parametros pelo STACK
                PUSH    R6                  	; Passagem de parametros pelo STACK
                CALL    EscString
WLOOP:        	ADD	R6, 0100h
                PUSH    VarTexto2           	; Passagem de parametros pelo STACK
                PUSH    R6                  	; Passagem de parametros pelo STACK
                CALL    EscString
		MOV	R7, R6
		SHR	R7, 8
		CMP	R7, 0016h
		JMP.N	WLOOP
		ADD	R6, 0100h
		PUSH	VarTexto1
		PUSH 	R6
		CALL	EscString
		POP 	R7
		POP	R6
		RET	
;===============================================================================
;INICIA TEMPO-DISPLAY
;CONVERSÃO DECIMAL		
;===============================================================================
EscDisplay: 	PUSH	R1
		PUSH	R2
		MOV 	R1, M[TTOTAL]
		MOV 	R2, 3E8H	
		DIV	R1, R2		
		MOV 	M[DISP7S4], R1			;determinação do 1º digito (maior ordem) do tempo de execução em decimal e escrita no display mais à esquerda
		MOV 	R1, 64H
		DIV 	R2, R1
		MOV 	M[DISP7S3], R2			;determinação do 2º digito (mais significativo) do tempo de execução em decimal e escrita no display 3
		MOV 	R2, AH
		DIV 	R1, R2	
		MOV 	M[DISP7S2], R1			; determinação do 3º digito (mais significativo) do tempo de execução em decimal e escrita no display	2
		MOV 	M[DISP7S1], R2			;determiação do digito menos significativo e escrita no display mais à direita da placa
		POP 	R2
		POP  	R1
		RET 
			
;===============================================================================
;ApagaNave: Rotina que apaga a nave da janela de texto
;===============================================================================
ApagaNave:	PUSH	VarTexto3
		PUSH	R2   
		CALL	EscString
		
		MOV R3, M[IO_READ]	
		RET
;===============================================================================
;EscreveNave: Rotina que escreve a nave na janela de texto
;===============================================================================

EscreveNave:	PUSH	VarNave
		PUSH	R2
		CALL	EscString
		MOV	R3, M[IO_READ]
		RET

;===============================================================================
;InitMatrixPos: Rotina que inicializa a matrix posição dos alígenas
;===============================================================================

InitMatrixPos:	PUSH	R1
		PUSH	R2
		PUSH	R3
		PUSH	R4
		PUSH	R5
		PUSH	R6
		MOV	R1, 0000h
		MOV	R2, 0000h
		MOV	R5, M[XY_Alien]		;Posição do primeiro alien a ser escrito
LOOP_InitPos:	INC	R1
		CMP	R1, 0007h		;Final das colunas de aliens
		JMP.P	FIM_InitPos
LOOP_Init2Pos:	INC	R2
		CMP	R2, 0004h		;Final das linhas de aliens
		JMP.P	RESET_InitPos
		MOV	R3, R1
		MOV	R4, R2
		MOV	R6, 0007h
		MUL	R6, R4
		ADD	R4, R3
		ADD	R4, MATRIX_POS		;Acesso à matriz de posição
		MOV	M[R4], R5		;Guarda posição onde escrever o alien
		ADD	R5, 0300h		;Incremento da linha
		JMP	LOOP_Init2Pos
		
RESET_InitPos:	MOV	R2, 0000h
		SUB	R5, 0C00h		;Reset da linha onde escrever
		ADD	R5, 0006h		;Incremento da coluna
		JMP	LOOP_InitPos

FIM_InitPos:	POP	R6
		POP	R5
		POP	R4
		POP	R3
		POP	R2
		POP	R1
		RET

;===============================================================================
;InitMatrix: Rotina que inicializa a matrix existêncial dos alígenas
;===============================================================================

InitMatrix:	PUSH	R1
		PUSH	R2
		PUSH	R3
		PUSH	R4
		PUSH	R5
		PUSH	R6
		MOV	R1, 0000h
		MOV	R2, 0000h
		MOV	R5, 0001h
LOOP_Init:	INC	R1
		CMP	R1, 0007h	;Final das colunas
		JMP.P	FIM_Init
LOOP_Init2:	INC	R2
		CMP	R2, 0004h	;Final das linhas
		JMP.P	RESET_Init
		MOV	R3, R1
		MOV	R4, R2
		MOV	R6, 0007h
		MUL	R6, R4
		ADD	R4, R3
		ADD	R4, MATRIX	;Acesso à matriz existêncial
		MOV	M[R4], R5	;Colocar todas as entradas a 1
		JMP	LOOP_Init2

RESET_Init:	MOV	R2, 0000h
		JMP	LOOP_Init

FIM_Init:	POP	R6
		POP	R5
		POP	R4
		POP	R3
		POP	R2
		POP	R1
		RET


;===============================================================================
;Escreve_Aliens_TEST: Rotina que escreve os aliens ainda vivos na janela de
;			 texto, com base na matriz posição e matriz existêncial
;===============================================================================


Escreve_Aliens_TEST:	PUSH	R1
			PUSH	R2
			PUSH	R3
			PUSH	R4
			PUSH	R5
			PUSH	R6
			MOV	R1, 0000h
			MOV	R2, 0000h		

LOOP_Escreve_TEST:	INC	R1
			CMP	R1, 0007h		;Final das colunas
			JMP.P	FIM_Escreve_TEST
LOOP_Escreve2_TEST:	INC	R2
			CMP	R2, 0004h		;Final das linhas
			JMP.P	RESET_Escreve_TEST
			MOV	R3, R1
			MOV	R4, R2
			MOV	R6, 0007h
			MUL	R6, R4
			ADD	R4, R3
			ADD	R4, MATRIX		;Acesso à matriz existêncial
			MOV	R6, M[R4]
			CMP	R6, 0001h		;Testa se o alien está vivo
			JMP.NZ	NaoEscreve_TEST
			MOV	R3, R1
			MOV	R4, R2
			MOV	R6, 0007h
			MUL	R6, R4
			ADD	R4, R3
			ADD	R4, MATRIX_POS		;Acesso à matriz Posição
			MOV	R5, M[R4]		;Posião do alien a escrever
			PUSH	Var_Alien
			PUSH	R5
			CALL	EscString		;Escrita do alien na janela

NaoEscreve_TEST:	JMP	LOOP_Escreve2_TEST

RESET_Escreve_TEST:	MOV	R2, 0000h
			JMP	LOOP_Escreve_TEST

FIM_Escreve_TEST:	POP	R6
			POP	R5
			POP	R4
			POP	R3
			POP	R2
			POP	R1
			RET

;===============================================================================
;Apaga_Aliens: Rotina que apaga as naves aliens na janela de texo
;===============================================================================

Apaga_Aliens:	PUSH	R1
		PUSH	R2
		PUSH	R3
		PUSH	R4
		PUSH	R5
		PUSH	R6
		MOV	R1, 0000h
		MOV	R2, 0000h
		MOV	R5, M[XY_Alien]		;Posição do primeiro alien a ser apagado
LOOP_Apaga:	INC	R1
		CMP	R1, 0007h		;Final das colunas
		JMP.P	FIM_Apaga
LOOP_Apaga2:	INC	R2
		CMP	R2, 0004h		;Final das linhas
		JMP.P	RESET_Apaga
		
		MOV	R6, R5
		SHR	R6, 8
		CMP	R6, 0015h		;Verifica se chegou à linha 15
		JMP.NN	Skip			;Não apaga para além desta linha
		
		PUSH	Var_Alien0
		PUSH	R5
		CALL	EscString		;Imprime espaço em branco
Skip:		ADD	R5, 0300h		;Incrementa linha
		JMP	LOOP_Apaga2

RESET_Apaga:	MOV	R2, 0000h
		SUB	R5, 0C00h		;Reset da linha
		ADD	R5, 0006h		;Incrementa coluna
		JMP	LOOP_Apaga	

FIM_Apaga:	POP	R6
		POP	R5
		POP	R4
		POP	R3
		POP	R2
		POP	R1
		RET
		
;===============================================================================
; Mover: Rotina que efectua o movimento da nave na janela de texto.
;===============================================================================	

Mover:		PUSH	R1
		PUSH	R2
		PUSH	R3
		PUSH	R4
		PUSH	R5
		PUSH	R7
		MOV	R2, M[CURSOR_POSITION]	;Posição da nave
		MOV	R5, 0001h
		MOV	M[SentidoMov], R5	;Sentido do movimento dos aliens
Escreve:	CALL	EscreveNave
		MOV	R4, M[Victory]
		CMP	R4, 0001h		;Verifica vitoria
		JMP.Z	Vitoria
		MOV	R4, M[Defeat]
		CMP	R4, 0001h		;Verifica Derrota
		JMP.Z	Derrota
		MOV	R4, M[Mover_Aliens]	;Variavel que determina se é tempo de mover os aliens
		MOV	R1, M[INT_7]		;R1 toma o valor em memória dos botões de interrupção
		SHR	R1, 7			;r1 toma apenas o valor do botao de interrupção 7(modo super-rapido)
		TEST	R1, 1H			; teste para o caso de ativo
		JMP.NZ	Alien			; em caso do botão 7 não ativo salta para Alien (escrita)
		MOV	R1, M[INT_7]		;Novo teste
		SHR	R1, 7			
		TEST	R1, 1h
		JMP.NZ	AUX_3			;salto em caso do botão de interrupção 7 ativo (ignora o tempo de delay para o movimento dos alien)			
		CMP	R4, 0001h
		JMP.Z	Alien
AUX_3:		MOV	R4, M[Victory]
		CMP	R4, 0001h
		JMP.Z	Vitoria
		MOV	R4, M[Defeat]
		CMP	R4, 0001h
		JMP.Z	Derrota

		
Esquerda:	CMP	R3, 'a'			;Testa se foi pressionada a tecla "a"
		BR.NZ	Direita
		CALL	ApagaNave
		SUB	R2, 0001h		;Decrementa coluna
		MOV	R7, R2
		ROL	R7, 8
		SHR	R7, 8
		CMP	R7, 0000h		;Limite esquerdo da coluna
		JMP.P	Escreve
		ADD	R2, 0001h		;Re-incrementa a coluna
Direita:	CMP	R3, 'd'			;Testa se foi pressionada a tecla "d"
		JMP.NZ	Espaco
		CALL	ApagaNave
		ADD	R2, 0001h		;Incrementa coluna
		MOV	R7, R2
		ROL	R7, 8
		SHR	R7, 8
		CMP	R7, 004Bh		;Limite direito da coluna
		JMP.N	Escreve
		SUB	R2, 0001h		;Re-decrementa a coluna
Espaco:		CMP	R3, ' '			;Testa se a tecla espaço foi pressionada
		JMP.NZ	Escreve
		CALL	Dispara			;Dispara o lazer
		JMP	Escreve			;Reinicia o Loop
		POP	R7
		POP	R5
		POP	R4
		POP	R3
		POP	R2
		POP	R1
		RET

Alien:		CALL	GAME_OVER		;Testa se o jogo acabou
		CALL	Alien_Move		;Move os aliens
		MOV 	M[LEDS], R0		;Apaga os leds
		JMP	Escreve

Vitoria:	CALL	Delay			;Delay antes de anunciar a vitoria
		CALL	LimpaJanela
		MOV	R1, 081Fh
		PUSH	Var_Victory
		PUSH	R1
		CALL	EscString		
		MOV	R1, 0001H
		MOV	M[RESTART], R1		;Colocar a variavel RESTART a 1
		JMP	Reinicio		;Fazer o setup do novo jogo

Derrota:	CALL	Delay			
		CALL	LimpaJanela
		MOV	R1, 081Fh
		PUSH	Var_Defeat
		PUSH	R1
		CALL	EscString
		MOV	R1, 0001H
		MOV	M[RESTART], R1
		JMP	Reinicio

;===============================================================================
; GAME_OVER: Rotina que determina se o jogo acabou
;===============================================================================

GAME_OVER:	PUSH	R1
		PUSH	R3
		PUSH	R4
		PUSH	R5
		PUSH	R6
		PUSH	R7
		MOV	R1, 0000h
		MOV	R7, 0000h
		MOV	R5, 0001h
LOOP_OVER:	INC	R1
		CMP	R1, 0007h
		JMP.P	VICTORY_OVER	;Se nao houver nenhum alien vivo, o jogador ganhou
LOOP_OVER2:	INC	R7
		CMP	R7, 0004h
		JMP.P	RESET_OVER
		MOV	R3, R1
		MOV	R4, R7
		MOV	R6, 0007h
		MUL	R6, R4
		ADD	R4, R3
		ADD	R4, MATRIX	;Acesso à matriz existêncial
		MOV	R3, M[R4]
		CMP	R3, R5		;Procura uma posição que ainda esteja a 1
		JMP.Z	CRASH_OVER	;Determina que ainda ha aliens
		JMP	LOOP_OVER2

RESET_OVER:	MOV	R7, 0000h
		JMP	LOOP_OVER

;;;;;;;;;;;;	


CRASH_OVER:	MOV	R1, 0000h
		MOV	R7, 0000h
LOOP_CRASH:	INC	R1
		CMP	R1, 0007h
		JMP.P	FIM_OVER
LOOP_CRASH2:	INC	R7
		CMP	R7, 0004h
		JMP.P	RESET_CRASH
		MOV	R3, R1
		MOV	R4, R7
		MOV	R6, 0007h
		MUL	R6, R4
		ADD	R4, R3
		ADD	R4, MATRIX	;Acesso à matriz existêncial
		MOV	R3, M[R4]
		CMP	R3, 0001h	;Verifica se o alien está vivo
		JMP.NZ	LOOP_CRASH2

		MOV	R3, R1
		MOV	R4, R7
		MOV	R6, 0007h
		MUL	R6, R4
		ADD	R4, R3
		ADD	R4, MATRIX_POS	;Acesso à entrada da matriz posição do alien que está vivo
		MOV	R3, M[R4]

		SHR	R3, 8
		CMP	R3, 0015h	;Verifica se está na linha 15
		JMP.z	DEFEAT_OVER	;Se estiver o jogador perdeu o jogo, pois ja nao tem hipotesse de o matar
		JMP	LOOP_CRASH2

RESET_CRASH:	MOV	R7, 0000h
		JMP	LOOP_CRASH

DEFEAT_OVER:	MOV	R6, 0001h
		MOV	M[Defeat], R6	;Variável Defeat a 1
		JMP	FIM_OVER

VICTORY_OVER:	MOV	M[Victory], R5	;Variavel Victory a 1

FIM_OVER:	POP	R7
		POP	R6
		POP	R5
		POP	R4
		POP	R3
		POP	R1
		RET

;===============================================================================
; Dispara: Rotina que dispara o lazer da nave
;===============================================================================

Dispara:	PUSH	R7
		PUSH	R4
		PUSH	R3
		PUSH	R5
		MOV	R5, R0	
		MOV	R7, R2
		ADD	R7, 0002h
		SUB	R7, 0100h
		MOV	R3, R7		;Posição do centro da nave

FLOOP:		CALL 	Hit		;Verifica se acertou em algum alien
		CMP	R5, 0001h	;Variável que nos diz se acertou ou não
		JMP.Z	ALOOP
		
		CALL	Lazer		;Escreve uma porção do lazer na janela
		PUSH	R6
		MOV 	R6, FFFFH
		MOV	M[LEDS], R6	;Acende os leds
		POP R6

		SUB	R7, 0100h	;Decrementa linha
		MOV	R4, R7
		SHR	R4, 8
		CMP	R4, 0001h	;Limite superior do espaço de jogo
		JMP.NZ	FLOOP
		CALL	Delay		;Delay para que seja visivel o lazer
ALOOP:		CMP	R3, R7
		JMP.N	FIM_D
		CALL	ApagaLazer	;Apaga toda a extensão do lazer
		SUB	R3, 0100h
		JMP	ALOOP
FIM_D:		POP	R5
		POP	R3
		POP	R4
		POP	R7
		RET

;===============================================================================
; Lazer: Rotina que escreve o lazer na janela de texto.
;===============================================================================		

Lazer:		PUSH	VarLazer
		PUSH	R7
		CALL	EscString		
		RET

;===============================================================================
; ApagaLazer: Rotina que escreve o lazer na janela de texto.
;===============================================================================

ApagaLazer:	PUSH	VarLazer0
		PUSH	R3
		CALL	EscString
		RET

;===============================================================================
; Hit: Rotina que verifica se o lazer da nave atingiu algum alien
;===============================================================================

Hit:		PUSH	R1
		PUSH	R2
		PUSH	R3
		PUSH	R4
		PUSH	R6
		MOV	R1, 0000h´
		
		MOV	R2, 0000h
LOOP_Hit:	INC	R1			
		CMP	R1, 0007h	;Limite das colunas
		JMP.P	FIM_Hit
LOOP_Hit2:	INC	R2			
		CMP	R2, 0004h	;Limite das linhas
		JMP.P	RESET_Hit
		MOV	R3, R1	
		MOV	R4, R2
		MOV	R6, 0007h
		MUL	R6, R4
		ADD	R4, R3
		ADD	R4, MATRIX_POS	;Acesso à matriz posição
		MOV	R6, M[R4]
		CMP	R7, R6		;Compara a posição do lazer com a posição do alien
		JMP.Z	Dead		;Se forem iguais o alien morre
		ADD	R6, 0001h
		CMP	R7, R6		;Alien ocupa 3 colunas
		JMP.Z	Dead
		ADD	R6, 0001h
		CMP	R7, R6		;Testam-se todas
		JMP.Z	Dead		
		JMP	LOOP_Hit2

RESET_Hit:	MOV	R2, 0000h
		JMP	LOOP_Hit

Dead:		MOV	R3, R1
		MOV	R4, R2
		MOV	R6, 0007h
		MUL	R6, R4
		ADD	R4, R3
		ADD	R4, MATRIX	;Acesso à matrix existêncial
		MOV	R6, M[R4]
		CMP	R6, 0001h	;Vê se o alien já estava morto
		JMP.Z	Dead2		
		JMP	LOOP_Hit2	;Caso estivesse continua a procurar

Dead2:		MOV	M[R4], R0	;Colocar a zero a entrada da matriz
		CALL	PONTUACAO	;Aumentar a pontuação
		MOV	R5, 0001h	;Constatar que foi atingido um alien
		

FIM_Hit:	POP	R6
		POP	R4
		POP	R3
		POP	R2
		POP	R1
		RET
;===============================================================================
;ROTINA DE PONTOS
;===============================================================================
PONTUACAO:	PUSH 	R1
		MOV 	R1, M[PONTOS]		;R1 toma o valor  de pontos do jogador;	
		ADD 	R1, 5H			; Adição de 5 pontos (o que vale cada alien)
		MOV 	M[PONTOS], R1		; colocação do valor atual de pontos na memória 
		CALL	LCD_ROTINA		;escrita no LCD

FIM2:		POP	R1
		RET
	
;===============================================================================
;Rotina_seg: Rotina que determina o tempo 
;===============================================================================

Rotina_seg: 	PUSH 	R1
		MOV 	R1, M[TTOTAL]
		INC	R1
		MOV	M[TTOTAL], R1
		CALL	EscDisplay
		POP 	R1
		RET

;===============================================================================
; Alien_Move: Rotina que move os aliens na janela de texto.
;===============================================================================

Alien_Move:	PUSH	R1
		PUSH	R2
		PUSH	R3
		MOV	R2, M[XY_Alien]		;Posição do primeiro alien a ser escrito
		MOV 	R1, M[TEMPO]
TES_TES:	MOV	R3, M[INT_7]		;Verificação dos botões interrupção ativos
		SHR	R3,7
		CMP	R3, 0001h		;comparação com o valor do botão 7 (o mais à esquerda)
		JMP.Z	AUX			;salto pois já não queremos contar o tempo 
		
		INC 	R1			;incremento do tempo 
		MOV 	M[TEMPO], R1		
		CMP	R1, 10			;comparação para saber se já contou um segundo (conta em 100 ms, e por isso 10*100ms=1s)
		JMP.Z	CONTA
		
AUX:		MOV	R1, M[SentidoMov]		
		CALL	PAUSA1
		CMP	R1, 0001h		;Verifica se os aliens se movem para a direita
		JMP.Z	MDireita
		SUB	R2, 0001h		;Decrementa a coluna
		MOV	R3, R2
		ROL	R3, 8
		SHR	R3, 8
		CMP	R3, 0000h		;Verifica se chegou ao limite esquerdo
		JMP.NP	MUDA_DIR		;Se sim, muda de direcção
		CALL	Apaga_Aliens
		MOV	M[XY_Alien], R2		;Update da posição do primeiro alien a ser escrito
		
		CALL	InitMatrixPos		;Update das posições de todos os aliens
		CALL	Escreve_Aliens_TEST	;Escrita dos aliens na janela
		JMP	FIM_AMOV
MDireita:	ADD	R2, 0001h
		MOV	R3, R2
		ROL	R3, 8
		SHR	R3, 8
		CMP	R3, 0029h		;Verifica se chegou ao limite direito
		JMP.NN	MUDA_ESQ
		CALL	Apaga_Aliens
		MOV	M[XY_Alien], R2

		CALL	InitMatrixPos
		CALL	Escreve_Aliens_TEST
		JMP	FIM_AMOV

CONTA:		CALL	Rotina_seg		
		MOV 	M[TEMPO],R0		;a variavel de contagem do tempo em ms (até um segundo) retorna o valor 0
		JMP	AUX	
MUDA_DIR:	MOV	R1, 0001h
		MOV	M[SentidoMov], R1	;Altera o sentido de movimento
		JMP	DOWN

MUDA_ESQ:	MOV	M[SentidoMov], R0	;Altera o sentido de movimento
		JMP DOWN

DOWN:		MOV	R2, M[XY_Alien]		;Incrementa a linha onde escrever os alien
		ADD	R2, 0100h
		CALL	Apaga_Aliens
		MOV	M[XY_Alien], R2

		CALL	InitMatrixPos
		CALL	Escreve_Aliens_TEST
FIM_AMOV:	MOV	M[Mover_Aliens], R0	;Repõe o valor 0
		
		POP	R3
		POP	R2
		POP	R1
		RET
;===============================================================================
; ROTINA DE PAUSA
;===============================================================================
PAUSA1:		PUSH 	R3
LOOPX:		MOV	R3, RotinaPausa		;chama a interrupção de pausa
		MOV	M[INT_A], R3		;variável toma um valor 
		MOV	R3, 8401h 		;ativação da mascara (disponibilização da utilização do tempo, IA , I0
		MOV	M[MASCARA_INT], R3
		MOV	R3, M[PAUSA]		
		CMP 	R3, R0
		BR.NZ	LOOPX			;Caso o R3 não seja zero, o programa fica neste ciclo à espera que tome o valor 0, e efetua-se a pausa
		POP	R3
		RET	

;===============================================================================
; Iniciar: Rotina que escreve o ecrã principal na janela de texto.
;===============================================================================

Iniciar:	PUSH	R2
		MOV 	R2, M[RESTART]	;Verifica se o jogo está a fazer o setup pela primeira vez
		CMP	R2, 0001H	;Decide o que escrever em cada caso
		JMP.Z	INICIAR2	
		MOV	R2, 0A1Fh
		PUSH	VarIniciar	;Start
		PUSH	R2
		CALL	EscString
		JMP	FIM_INI_RE
INICIAR2:	MOV	R2, 0A1Fh
		PUSH	VarReinicar	;Restart
		PUSH	R2
		CALL	EscString
FIM_INI_RE:	POP 	R2
		RET
;===============================================================================
;RotinaPausa:	Rotina de atendiamento à interrupção IA
;===============================================================================
RotinaPausa:	PUSH 	R1
		PUSH	R2
		MOV 	R2, M[PAUSA]
		CMP	R2, R0
		BR.NZ	LOOPP		; caso a M[PAUSA] diferente de 0, voltamos a colocar esta variável a zero (deixou da haver pausa)		
		MOV	R1, 0001H	; caso a M[PAUSA] nao seja 0, passa a tomar o valor de 1, isto é efetua-se a pausa
		MOV	M[PAUSA], R1
		BR	FIM
LOOPP:		MOV	M[PAUSA],R0	
FIM:		POP 	R2
		POP	R1
		RTI
;===============================================================================
;RotinaInt0: Rotina de atendimento à interrupção IO
;===============================================================================

RotinaInt0:	PUSH	R1
		MOV	R1, 0001h
		MOV	M[Start], R1		;end correspondente a Start =1
		POP	R1
		RTI

;===============================================================================
;RotinaIntTemp: Rotina de atendimento à interrupção do temporizador
;===============================================================================

RotinaIntTemp:	PUSH	R1
		MOV	R1,0001h 
		MOV	M[Mover_Aliens], R1 	;colocação a 1 de mover_aliens
		MOV	M[TempControlo], R1	;ativação do tempo
		MOV	R1, 0001h
		MOV	M[Temp_Aliens], R1	;unidade de contagem
		POP 	R1
		RTI

;===============================================================================
;InitInt: Inicializa TVI, Mascara de INT e Temporizador
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================
InitInt:        PUSH	R1
		MOV     R1, RotinaInt0		;"chamamento da interrupção"
                MOV     M[Int_0], R1		;MOV para a memoria o valor da int.
		MOV     R1, RotinaIntTemp
                MOV     M[TAB_INTTemp], R1
		MOV	R1,8001h 		;atualização da mascara de interrupções (o temporizador e I0)
		MOV	M[MASCARA_INT], R1
		MOV	R1,0001h 		;unidades de contagem do tempo (100ms)
		MOV	M[Temp_Aliens], R1
		MOV	R1,0001h 
		MOV	M[TempControlo], R1	;inicio da contagem do tempo
                ENI
		POP	R1
                RET

;===============================================================================
; EscString: Rotina que efectua a escrita de uma cadeia de caracter, terminada
;            pelo caracter FIM_TEXTO, na janela de texto numa posicao 
;            especificada. Pode-se definir como terminador qualquer caracter 
;            ASCII. 
;               Entradas: pilha - posicao para escrita do primeiro carater 
;                         pilha - apontador para o inicio da "string"
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

EscString:      PUSH    R1
                PUSH    R2
		PUSH    R3
                MOV     R2, M[SP+6]   ; Apontador para inicio da "string"
                MOV     R3, M[SP+5]   ; Localizacao do primeiro carater
Ciclo:          MOV     M[IO_CURSOR], R3
                MOV     R1, M[R2]
                CMP     R1, FIM_TEXTO
                BR.Z    FimEsc
                CALL    EscCar
                INC     R2
                INC     R3
                BR      Ciclo
FimEsc:         POP     R3
                POP     R2
                POP     R1
                RETN    2                ; Actualiza STACK

;===============================================================================
; EscCar: Rotina que efectua a escrita de um caracter para o ecran.
;         O caracter pode ser visualizado na janela de texto.
;               Entradas: R1 - Caracter a escrever
;               Saidas: ---
;               Efeitos: alteracao da posicao de memoria M[IO]
;===============================================================================

EscCar:         MOV     M[IO_WRITE], R1
                RET                     

;===============================================================================
; Delay: Rotina que permite gerar um atraso
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

Delay:          PUSH    R1
                MOV     R1, DELAYVALUE
DelayLoop:      DEC     R1
                BR.NZ   DelayLoop
                POP     R1
                RET
;===============================================================================
;LCD_ROTINA
;===============================================================================
LCD_ROTINA:	PUSH 	R1
		PUSH	R2
		PUSH	R3
		MOV 	R1, 'P'
		MOV 	R2, 8000h
		CALL	LCD_ESC
		MOV 	R1, 'O'
		MOV 	R2, 8001H
		CALL	LCD_ESC
		MOV 	R1, 'N'
		MOV 	R2, 8002H
		CALL	LCD_ESC
		MOV 	R1, 'T'
		MOV 	R2, 8003H
		CALL	LCD_ESC
		MOV 	R1, 'U'
		MOV 	R2, 8004H
		CALL	LCD_ESC
		MOV 	R1, 'A'
		MOV 	R2, 8005H
		CALL	LCD_ESC
		MOV 	R1, 'C'
		MOV 	R2, 8006H
		CALL 	LCD_ESC
		MOV 	R1, 'A'
		MOV 	R2, 8007H
		CALL	LCD_ESC
		MOV 	R1, 'O'
		MOV 	R2, 8008H
		CALL	 LCD_ESC
		MOV 	R1, ':'
		MOV 	R2, 8009H
		CALL	LCD_ESC
		MOV 	R1, ' '
		MOV 	R2, 800AH
		CALL	LCD_ESC
		MOV 	R1, 0030H
		MOV	R2,800BH
		CALL	LCD_ESC
		MOV 	R1, 0030H
		MOV	R2,800CH
		CALL 	LCD_ESC
		MOV 	R1, M[PONTOS]		; determinação do 1º digito de maior peso  (centenas) no LCD da placa 
		MOV 	R3, 64h
		DIV	R1, R3
		ADD	R1, 0030H		
		MOV	R2,800BH		; posição de escrita no lcd
		CALL	LCD_ESC			; escrita do 1º digito de maior peso  (centenas) no LCD da placa 
		MOV	R1,R3			;mover o resto da divisão anterior para o r1
		MOV 	R3, AH			; mover 10 para r3
		DIV 	R1, R3			
		ADD	R1, 0030H		;em r1 temos o valor das dezenas de pontos
		MOV 	R2, 800CH		;posição de escrita  no lcd
		CALL 	LCD_ESC		
		MOV	R1,R3			;r1 tem o valor do resto da divisão anteriro
		MOV 	R3, 1H
		DIV 	R1, R3	
		ADD	R1, 0030H		; digito das unidades (dos pontos)
		MOV 	R2, 800DH
		CALL 	LCD_ESC		
fim: 		POP 	R3
		POP 	R2
		POP  	R1
		RET 

;=========================================================
;ESCRITA NO LCD DE CARACTER/VALOR
;=========================================================
LCD_ESC:	MOV 	M[LCD_CURSOR], R2	;Posição de escrita
		MOV 	M[LCD_WRITE], R1	;"STRING" a escrever
		RET

		
;===============================================================================
;                                Programa principal
;===============================================================================
inicio:         CALL    LimpaJanela
Reinicio:	MOV     R1, SP_INICIAL		;Setup inicial do jogo
                MOV     SP, R1			;
		CALL 	InitInt			;
		CALL	InitMatrix		;	
		CALL	Iniciar			;
		MOV	R1, 031Ch		;
		MOV	M[XY_Alien], R1		;
		CALL	InitMatrixPos		;
		MOV	M[Start], R0		;
		MOV 	M[TEMPO],R0		;
		MOV 	M[TTOTAL],R0		;
		MOV	M[DISP7S1], R0		;
		MOV	M[DISP7S2], R0		;
		MOV	M[DISP7S3], R0		;
		MOV	M[DISP7S4], R0		;
		MOV 	M[PAUSA], R0		;
		MOV	M[PONTOS],R0		;
		MOV	M[Victory], R0		;
		MOV	M[Defeat], R0		;
		MOV 	M[RESTART],R0		;
		CALL	LCD_ROTINA		;
Ini:		MOV	R1, M[Start]		
		CMP	R1, 0001h
		JMP.NZ	Ini
		CALL	LimpaJanela
                CALL    EspJogo
		CALL	Mover

Fim:            BR Fim
;===============================================================================
