[ORG 0x00]              ; 메모리 시작 번지를 알려주는 선언문
[BITS 16]               ; 이 프로그램이 16비트 단위로 데이터를 처리하는 프로그램임을 알려주는 선언문

SECTION .text           ; text 섹션 정의

; 코드 영역
START:
    mov ax, 0x1000      ; 보호모드의 시작 주소를 세그먼트 레지스터에 설정
    mov ds, ax
    mov es, ax

    cli                 ; 인터럽트가 발생하지 못하도록 설정
    lgdt [ GDTR ]       ; GDTR 자료구조를 프로세서에 설정하여 GDT 테이블 로드

    ; 보호모드 진입
    mov eax, 0x4000003B    ; PG=0, CD=1, NW=0, AM=0, WP=0, NE=1, ET=1, TS=1, EM=0, MP=1, PE=1
    mov cr0, eax           ; CR0 컨트롤 레지스터에 위에서 저장한 플래그를 설정하여 보호 모드로 전환

    ; 커널 코드 세그먼트를 0x00 기준으로 하는 것으로 교체하고 EIP의 값을 0x00을 기준으로 재설정
    ; CS 세그먼트 셀렉터 : EIP
    jmp dword 0x08: ( PROTECTEDMODE - $$ + 0x10000 )

    [BITS 32]
    PROTECTEDMODE:
        mov ax, 0x10    ; 보호모드 커널용 데이터 세그먼트 디스크립터 저장
        mov ds, ax      ; DS 세그먼트 셀렉터에 설정
        mov es, ax      ; ES 세그먼트 셀렉터에 설정
        mov fs, ax      ; FS 세그먼트 셀렉터에 설정
        mov gs, ax      ; GS 세그먼트 셀렉터에 설정

        ; 스택을 0x00000000 ~ 0x0000FFFF 영역에 64KB 크기로 생성
        mov ss, ax      ; SS 세그먼트 셀렉터에 설정
        mov esp, 0xFFFE
        mov ebp, 0xFFFE

        ; 화면에 보호 모드로 전환되었다는 메시지를 찍음
        push ( SWITCHSUCCESSMESSAGE - $$ + 0x10000 )    ; 출력할 메시지의 어드레스를 스택에 삽입
        push 2
        push 0
        call PRINTMESSAGE
        add esp, 12         ; 파라미터 정리

        jmp $

    ; 함수 코드 영역
    ; 메시지 출력 함수 (32비트)
    PRINTMESSAGE:
        push ebp
        mov ebp, esp
        push esi
        push edi
        push eax
        push ecx
        push edx

        ;=================================
        ; X ,Y의 좌표로 비디오 메모리의 어드레스를 구함
        ;=================================
        mov eax, dword [ ebp + 12 ]   ; 2번째 파라미터 값을(y 좌표) eax로 복사
        mov esi, 160                ; 한 라인의 바이트수 ( 80(라인문자개수) * 2(문자값+속성) )
        mul esi                     ; 파라미터 값과 곱하여 y 좌표 계산
        mov edi, eax                ; edi 레지스터에 y좌표값 저장

        mov eax, dword [ ebp + 8 ]   ; 1번째 파라미터 값을 (x 좌표)
        mov esi, 2                  ; 문자의 바이트 수 (문자값+속성)
        mul esi                     ; 파라미터 값과 곱하여 x 좌표 계산
        add edi, eax                ; y좌표값과 더하여 비디오 메모리 어드레스 계산

        mov esi, dword [ ebp + 16 ]  ; esi 레지스터에 출력할 문자열 주소 저장

    .MESSAGELOOP:   ; 메세지 출력 함수
        mov cl, byte [ esi ]        ; 메세지가 저장된 주소에서 esi 인덱스의 값을 가져옴

        cmp cl, 0                   ; 문자열의 끝인지 비교
        je .MESSAGEEND              ; 끝이면 MESSAGEEND로 점프

        mov byte [ edi + 0xB8000 ], cl ; 문자 값을 비디오 메모리에 삽입

        add esi, 1   ; 문자열 인덱스 ++
        add edi, 2   ; 비디오 메모리 인덱스++ (문자 + 속성 = 2바이트)

        jmp .MESSAGELOOP

    .MESSAGEEND:
        ; 6개의 레지스터 값 스택에 임시 저장 FILO 구조라 역순으로 POP
        pop edx
        pop ecx
        pop eax
        pop edi
        pop esi
        pop ebp     ; 베이스 포인터 복구
        ret         ; ret = pop eip, jmp eip

    ; 데이터 영역
    align 8, db 0

    dw 0x0000
    ; GDTR 자료구조 정의
    GDTR:
        dw GDTEND - GDT - 1         ; 아래에 위치하는 GDT 테이블의 전체 크기
        dd ( GDT - $$ + 0x10000 )   ; 아래에 위치하는 GDT 테이블의 시작 어드레스

    ; GDT 테이블 정의
    GDT:
        ; 널 디스크립터. 0으로 초기화 하여야 함
        NULLDescriptor:
            dw 0x0000
            dw 0x0000
            db 0x00
            db 0x00
            db 0x00
            db 0x00

        CODEDESCRIPTOR:
            dw 0xFFFF   ; Limit [15:0]
            dw 0x0000   ; Base [15:0]
            db 0x00     ; Base [23:16]
            db 0x9A     ; P=1, DPL=0, Code Segment, Execute/Read
            db 0xCF     ; G=1, D=1, L=0, Limit[19:16]
            db 0x00     ; Base [31:24]

        ; 보호 모드 커널용 데이터 서그먼트 디스크립터
        DATADESCRIPTOR:
            dw 0xFFFF   ; Limit [15:0]
            dw 0x0000   ; Base [15:0]
            db 0x00     ; Base [23:16]
            db 0x92     ; P=1, DPL=0, Data Segment, Read/Write
            db 0xCF     ; G=1, D=1, L=0, Limit [19:16]
            db 0x00     ; Base [31:24]
    GDTEND:

    ; 보호 모드 전환 메시지
    SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success~!!', 0

    times 512 - ( $ - $$ ) db 0x00
