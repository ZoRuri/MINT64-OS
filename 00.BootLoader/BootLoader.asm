[ORG 0x00]  ; �޸� ���� ������ �˷��ִ� ����
[BITS 16]   ; �� ���α׷��� 16��Ʈ ������ �����͸� ó���ϴ� ���α׷����� �˷��ִ� ����

SECTION .text   ; text ���� ����

jmp 0x07C0:START   ; CS ���׸�Ʈ �������� 0x07C0�� �����ϸ鼭 START ���̺�� �̵�

;====================
; MINT64 OS ȯ�� ���� ��
;====================
TOTALSECTORCOUNT:   dw 1 ; ��Ʈ �δ��� ������ MINT64 OS �̹��� ũ��
                            ; �ִ� 1152 ����(0x90000bytes)���� ����

;====================
; �ڵ� ����
;====================
START:
	mov ax, 0x07C0 ; 8086 ���μ��������� ���׸�Ʈ�� ���� ���� ���� �� ���� (���� ���� �������͸� �̿�)
	mov ds, ax     ; DS ���׸�Ʈ �������Ϳ� ���� ��巹�� ����
    mov ax, 0xB800  ; ���� �޸� ��巹��
    mov es, ax      ; ES ���׸�Ʈ �������Ϳ� ����

    ; ���� ���� (0x000:0000 ~ 0x0000:FFFF)
    mov ax, 0x0000
    mov ss, ax
    mov sp, 0xFFFE
    mov bp, 0xFFFE

    mov si, 0   ; index �ʱ�ȭ

.SCREENCLEARLOOP:   ; ȭ�� clear �Լ�
    mov byte [ es: si ], 0      ; ���� ����
    mov byte [ es: si + 1 ], 0x0A   ; �Ӽ� �� ����, ����� ����

    add si, 2

    cmp si, 80 * 25 * 2
    jl .SCREENCLEARLOOP

    ; ���� �޽��� ���
    push MESSAGE1
    push 0
    push 0
    call PRINTMESSAGE   ; �޽��� ��� �Լ� ȣ��
    add sp, 6           ; �Ķ���� ����

    ; OS �̹��� �ε� �޽��� ���
    push IMAGELOADINGMESSAGE
    push 1
    push 0
    call PRINTMESSAGE
    add sp, 6

;======================
; ��ũ���� OS �̹����� �ε�
;======================
; ��ũ�� �б� ���� �ʱ�ȭ
RESETDISK:   ; �ʱ�ȭ �ڵ�
    ; # BIOS Reset Function ȣ��
    ; ���� ��ȣ 0, ����̺� ��ȣ(0=Floppy)
    mov ax, 0
    mov dl, 0
    int 0x13    ; ���ͷ�Ʈ 0x13 ȣ��
    jc HANDLEDISKERROR  ; ���� �߻��� ���� ó��

    ; �޸𸮷� ������ ��巹��(ES:BX)�� 0x10000���� ����
    mov si, 0x1000
    mov es, si
    mov bx, 0x0000

    mov di, word [ TOTALSECTORCOUNT ] ; ������ OS �̹����� ���� ���� DI �������Ϳ� ����

READDATA:
    ; ��� ���͸� �� �о����� Ȯ��
    cmp di, 0
    je READEND
    sub di, 0x1

    ; # BIOS Read Function ȣ��
    mov ah, 0x02                    ; BIOS ���� ��ȣ 2(Read Sector)
    mov al, 0x1                     ; ���� ���� �� ����
    mov ch, byte [ TRACKNUMBER ]    ; ���� Ʈ�� ��ȣ ����
    mov cl, byte [ SECTORNUMBER ]   ; ���� ���� ��ȣ ����
    mov dh, byte [ HEADNUMBER ]     ; ���� ��� ��ȣ ����
    mov dl, 0x00                    ; ���� ����̺� ��ȣ(0=Floppy) ����
    int 0x13
    jc HANDLEDISKERROR              ; ����ó��

    ; ������ ��巹���� Ʈ�� ���, ���� ��巹�� ���
    add si, 0x0020  ; 1����(512����Ʈ = 0x200) �о����Ƿ� ���׸�Ʈ �������Ϳ� ���� ������
    mov es, si      ; ���׸�Ʈ���� �ѹ��� ���� ���־� ���뷹������ �̿�

    ; *�����ڵ�
    ; �� ���͸� �а� ���� ������Ű�� ������ ����(18)���� ������ ����ڵ����� �̵�
    mov al, byte [ SECTORNUMBER ]
    add al, 0x01
    mov byte [ SECTORNUMBER ], al
    cmp al, 19
    jl READDATA

    ; *����ڵ�
    xor byte [ HEADNUMBER ], 0x01
    mov byte [ SECTORNUMBER ], 0x01 ; ����ȣ�� Toggle ��

    cmp byte [ HEADNUMBER ], 0x00   ; ��� ���� 0�̵Ǹ� ���� ��带 ��� �������̹Ƿ� Ʈ���ڵ�� �̵�
    jne READDATA

    ; *Ʈ���ڵ�
    add byte [ TRACKNUMBER ], 0x01 ; Ʈ�� ��ȣ�� 1 ����
    jmp READDATA

READEND:
    ; OS �̹����� �Ϸ�Ǿ��ٴ� �޽����� ���
    push LOADINGCOMPLETEMESSAGE
    push 1
    push 20
    call PRINTMESSAGE
    add sp, 6

    ;�ε��� ���� OS �̹��� ����
    jmp 0x1000:0x0000

;======================
; �Լ� �ڵ� ����
;======================
; ��ũ ���� ó�� �Լ�
HANDLEDISKERROR:
    push DISKERRORMESSAGE   ; ���� �޽���
    push 1
    push 20
    call PRINTMESSAGE

    jmp $   ; ���� ��ġ���� ���ѷ���

; �޽��� ��� �Լ�
; PARAM(x ��ǥ, y ��ǥ, ���ڿ�)
PRINTMESSAGE:
    push bp     ;�Լ� ���ѷα�
    mov bp, sp

    ; 6���� �������� �� ���ÿ� �ӽ� ����
    push es
    push si
    push di
    push ax
    push cx
    push dx

    ; ES ���׸�Ʈ�� ���� ��� ��巹��(0xB8000) ����
    mov ax, 0xB800
    mov es, ax

    ;=================================
    ; X ,Y�� ��ǥ�� ���� �޸��� ��巹���� ����
    ;=================================
    mov ax, word [ bp + 6 ] ; 2��° �Ķ���� ����(y ��ǥ) ax�� ����
    mov si, 160             ; �� ������ ����Ʈ�� ( 80(���ι��ڰ���) * 2(���ڰ�+�Ӽ�) )
    mul si                  ; �Ķ���� ���� ���Ͽ� y ��ǥ ���
    mov di, ax              ; di �������Ϳ� y��ǥ�� ����

    mov ax, word [ bp + 4 ] ; 1��° �Ķ���� ���� (x ��ǥ)
    mov si, 2               ; ������ ����Ʈ �� (���ڰ�+�Ӽ�)
    mul si                  ; �Ķ���� ���� ���Ͽ� x ��ǥ ���
    add di, ax              ; y��ǥ���� ���Ͽ� ���� �޸� ��巹�� ���

    mov si, word [ bp + 8 ] ; si �������Ϳ� ����� ���ڿ� �ּ� ����

.MESSAGELOOP:   ; �޼��� ��� �Լ�
    mov cl, byte [ si ] ; �޼����� ����� �ּҿ��� si �ε����� ���� ������

    cmp cl, 0   ; ���ڿ��� ������ ��
    je .MESSAGEEND  ; ���̸� MESSAGEEND�� ����

    mov byte [ es: di ], cl ; ���� ���� ���� �޸�(���� es ��������)�� ����

    add si, 1   ; ���ڿ� �ε��� ++
    add di, 2   ; ���� �޸� �ε���++ (���� + �Ӽ� = 2����Ʈ)

    jmp .MESSAGELOOP

.MESSAGEEND:
    ; 6���� �������� �� ���ÿ� �ӽ� ���� FILO ������ �������� POP
    pop dx
    pop cx
    pop ax
    pop di
    pop si
    pop es

    pop bp ; ���̽� ������ ����
    ret    ; ret = pop eip, jmp eip >_<

;=============
; ������ ����
;=============
; ��Ʈ�δ� ���� �޽���
MESSAGE1:   db 'MINT64 OS Boot Loader Start~!!', 0 ; ��� �޼���

DISKERRORMESSAGE:       db 'DISK Error~!!', 0
IMAGELOADINGMESSAGE:    db 'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE: db 'Complete~!!', 0

; ��ũ �б⿡ ���õ� ����
SECTORNUMBER:   db 0x02 ; OS �̹����� �����ϴ� ���� ��ȣ�� ����    (ù��° ���ʹ� ��Ʈ�δ��� ����)
HEADNUMBER:     db 0x00 ; OS �̹����� �����ϴ� ��� ��ȣ�� ����
TRACKNUMBER:    db 0x00 ; OS �̹����� �����ϴ� Ʈ�� ��ȣ�� ����

times 510 - ( $ - $$ )	db	0x00
; $: ���� ������ �ּ�
; $$: ���� ������ ���� �ּ�
; times �ݺ���

db 0x55
db 0xAA
