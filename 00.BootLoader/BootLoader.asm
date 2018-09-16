ORG 0x00	; 메모리 시작 번지를 알려주는 선언문
BITS 16	; 이 프로그램이 16비트 단위로 데이터를 처리하는 프로그램임을 알려주는 선언문


SECTION .text	; text 섹션 정의

mov ax, 0xB800  ; 0xB800 비디오 어드레스
mov ds, ax      ; DS 세그먼트 레지스터에 비디오 어드레스 값 값 복사

jmp 0x07C0:START   ; CS 세그먼트 레지스터 0x07C)을 복사하면서 START 레이블로 이동

START:
	mov ax, 0x07C0 ; 8086 프로세서에서는 세그먼트에 직접 값을 넣을 수 없음 (따라서 범용 레지스터를 이용)
	mov ds, ax     ; DS 세그먼트 레지스터에 시작 어드레스 지정

    mov ax, 0xB800  ; 비디오 메모리 어드레스
    mov es, ax      ; ES 세그먼트 레지스터에 설정

    mov si, 0   ; index 초기화

.SCREENCLEARLOOP:   ; 화면 clear 함수
    mov byte [ es: si ], 0      ; 문자 설정
    mov byte [ es: si + 1], 0x0A   ; 속성 및 배경색, 전경색 설정

    add si, 2

    cmp si, 80 * 24 * 2
    jl .SCREENCLEARLOOP

    ; index 초기화
    mov si, 0
    mov di, 0

.MESSAGELOOP:   ; 메세지 출력 함수
    mov cl, byte [ si + MESSAGE1 ] ; 메세지가 저장된 주소에서 si 인덱스의 값을 가져옴

    cmp cl, 0   ; 문자열의 끝인지 비교
    je .FINISH  ; 끝이면 FINISH로 점프

    mov byte[ es: di ], cl ; 문자 값을 비디오 메모리(현재 es 레지스터)에 삽입

    add si, 1   ; 문자열 인덱스 ++
    add di, 2   ; 비디오 메모리 인덱스++ (문자 + 속성 = 2바이트)

    jmp .MESSAGELOOP

.FINISH:
jmp $  ; loop


; 데이터 영역

MESSAGE1:   db 'MINT64 OS Boot Loader Start~!!', 0 ; 출력 메세지

times 510 - ( $ - $$ )	db	0x00
; $: 현재 라인의 주소
; $$: 현재 섹션의 시작 주소
; times 반복문

db 0x55
db 0xAA
