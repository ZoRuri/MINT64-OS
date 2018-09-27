[ORG 0x00]  ; 메모리 시작 번지를 알려주는 선언문
[BITS 16]   ; 이 프로그램이 16비트 단위로 데이터를 처리하는 프로그램임을 알려주는 선언문

SECTION .text   ; text 섹션 정의

jmp 0x07C0:START   ; CS 세그먼트 레지스터 0x07C0을 복사하면서 START 레이블로 이동

;====================
; MINT64 OS 환경 설정 값
;====================
TOTALSECTORCOUNT:   dw 1 ; 부트 로더를 제외한 MINT64 OS 이미지 크기
                            ; 최대 1152 섹터(0x90000bytes)까지 가능

;====================
; 코드 영역
;====================
START:
	mov ax, 0x07C0 ; 8086 프로세서에서는 세그먼트에 직접 값을 넣을 수 없음 (따라서 범용 레지스터를 이용)
	mov ds, ax     ; DS 세그먼트 레지스터에 시작 어드레스 지정
    mov ax, 0xB800  ; 비디오 메모리 어드레스
    mov es, ax      ; ES 세그먼트 레지스터에 설정

    ; 스택 생성 (0x000:0000 ~ 0x0000:FFFF)
    mov ax, 0x0000
    mov ss, ax
    mov sp, 0xFFFE
    mov bp, 0xFFFE

    mov si, 0   ; index 초기화

.SCREENCLEARLOOP:   ; 화면 clear 함수
    mov byte [ es: si ], 0      ; 문자 설정
    mov byte [ es: si + 1 ], 0x0A   ; 속성 및 배경색, 전경색 설정

    add si, 2

    cmp si, 80 * 25 * 2
    jl .SCREENCLEARLOOP

    ; 시작 메시지 출력
    push MESSAGE1
    push 0
    push 0
    call PRINTMESSAGE   ; 메시지 출력 함수 호출
    add sp, 6           ; 파라미터 정리

    ; OS 이미지 로딩 메시지 출력
    push IMAGELOADINGMESSAGE
    push 1
    push 0
    call PRINTMESSAGE
    add sp, 6

;======================
; 디스크에서 OS 이미지를 로딩
;======================
; 디스크를 읽기 전에 초기화
RESETDISK:   ; 초기화 코드
    ; # BIOS Reset Function 호출
    ; 서비스 번호 0, 드라이브 번호(0=Floppy)
    mov ax, 0
    mov dl, 0
    int 0x13    ; 인터럽트 0x13 호출
    jc HANDLEDISKERROR  ; 에러 발생시 에러 처리

    ; 메모리로 복사할 어드레스(ES:BX)를 0x10000으로 설정
    mov si, 0x1000
    mov es, si
    mov bx, 0x0000

    mov di, word [ TOTALSECTORCOUNT ] ; 복사할 OS 이미지의 섹터 수를 DI 레지스터에 설정

READDATA:
    ; 모든 섹터를 다 읽었는지 확인
    cmp di, 0
    je READEND
    sub di, 0x1

    ; # BIOS Read Function 호출
    mov ah, 0x02                    ; BIOS 서비스 번호 2(Read Sector)
    mov al, 0x1                     ; 읽을 섹터 수 설정
    mov ch, byte [ TRACKNUMBER ]    ; 읽을 트랙 번호 설정
    mov cl, byte [ SECTORNUMBER ]   ; 읽을 섹터 번호 설정
    mov dh, byte [ HEADNUMBER ]     ; 읽을 헤드 번호 설정
    mov dl, 0x00                    ; 읽을 드라이브 번호(0=Floppy) 설정
    int 0x13
    jc HANDLEDISKERROR              ; 에러처리

    ; 복사할 어드레스와 트랙 헤드, 섹터 어드레스 계산
    add si, 0x0020  ; 1섹터(512바이트 = 0x200) 읽었으므로 세그먼트 레지스터에 값을 더해줌
    mov es, si      ; 세그먼트에는 한번에 값을 못넣어 범용레지스터 이용

    ; *섹터코드
    ; 한 섹터를 읽고 값을 증가시키고 마지막 섹터(18)까지 읽으면 헤드코드으로 이동
    mov al, byte [ SECTORNUMBER ]
    add al, 0x01
    mov byte [ SECTORNUMBER ], al
    cmp al, 19
    jl READDATA

    ; *헤드코드
    xor byte [ HEADNUMBER ], 0x01
    mov byte [ SECTORNUMBER ], 0x01 ; 헤드번호를 Toggle 함

    cmp byte [ HEADNUMBER ], 0x00   ; 헤드 값이 0이되면 양쪽 헤드를 모두 읽은것이므로 트랙코드로 이동
    jne READDATA

    ; *트랙코드
    add byte [ TRACKNUMBER ], 0x01 ; 트랙 번호를 1 증가
    jmp READDATA

READEND:
    ; OS 이미지가 완료되었다는 메시지를 출력
    push LOADINGCOMPLETEMESSAGE
    push 1
    push 20
    call PRINTMESSAGE
    add sp, 6

    ;로딩한 가상 OS 이미지 실행
    jmp 0x1000:0x0000

;======================
; 함수 코드 영역
;======================
; 디스크 에러 처리 함수
HANDLEDISKERROR:
    push DISKERRORMESSAGE   ; 에러 메시지
    push 1
    push 20
    call PRINTMESSAGE

    jmp $   ; 현재 위치에서 무한루프

; 메시지 출력 함수
; PARAM(x 좌표, y 좌표, 문자열)
PRINTMESSAGE:
    push bp     ;함수 프롤로그
    mov bp, sp

    ; 6개의 레지스터 값 스택에 임시 저장
    push es
    push si
    push di
    push ax
    push cx
    push dx

    ; ES 세그먼트에 비디오 모드 어드레스(0xB8000) 설정
    mov ax, 0xB800
    mov es, ax

    ;=================================
    ; X ,Y의 좌표로 비디오 메모리의 어드레스를 구함
    ;=================================
    mov ax, word [ bp + 6 ] ; 2번째 파라미터 값을(y 좌표) ax로 복사
    mov si, 160             ; 한 라인의 바이트수 ( 80(라인문자개수) * 2(문자값+속성) )
    mul si                  ; 파라미터 값과 곱하여 y 좌표 계산
    mov di, ax              ; di 레지스터에 y좌표값 저장

    mov ax, word [ bp + 4 ] ; 1번째 파라미터 값을 (x 좌표)
    mov si, 2               ; 문자의 바이트 수 (문자값+속성)
    mul si                  ; 파라미터 값과 곱하여 x 좌표 계산
    add di, ax              ; y좌표값과 더하여 비디오 메모리 어드레스 계산

    mov si, word [ bp + 8 ] ; si 레지스터에 출력할 문자열 주소 저장

.MESSAGELOOP:   ; 메세지 출력 함수
    mov cl, byte [ si ] ; 메세지가 저장된 주소에서 si 인덱스의 값을 가져옴

    cmp cl, 0   ; 문자열의 끝인지 비교
    je .MESSAGEEND  ; 끝이면 MESSAGEEND로 점프

    mov byte [ es: di ], cl ; 문자 값을 비디오 메모리(현재 es 레지스터)에 삽입

    add si, 1   ; 문자열 인덱스 ++
    add di, 2   ; 비디오 메모리 인덱스++ (문자 + 속성 = 2바이트)

    jmp .MESSAGELOOP

.MESSAGEEND:
    ; 6개의 레지스터 값 스택에 임시 저장 FILO 구조라 역순으로 POP
    pop dx
    pop cx
    pop ax
    pop di
    pop si
    pop es

    pop bp ; 베이스 포인터 복구
    ret    ; ret = pop eip, jmp eip >_<

;=============
; 데이터 영역
;=============
; 부트로더 시작 메시지
MESSAGE1:   db 'MINT64 OS Boot Loader Start~!!', 0 ; 출력 메세지

DISKERRORMESSAGE:       db 'DISK Error~!!', 0
IMAGELOADINGMESSAGE:    db 'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE: db 'Complete~!!', 0

; 디스크 읽기에 관련된 변수
SECTORNUMBER:   db 0x02 ; OS 이미지가 시작하는 섹터 번호를 저장    (첫번째 섹터는 부트로더로 제외)
HEADNUMBER:     db 0x00 ; OS 이미지가 시작하는 헤드 번호를 저장
TRACKNUMBER:    db 0x00 ; OS 이미지가 시작하는 트랙 번호를 저장

times 510 - ( $ - $$ )	db	0x00
; $: 현재 라인의 주소
; $$: 현재 섹션의 시작 주소
; times 반복문

db 0x55
db 0xAA
