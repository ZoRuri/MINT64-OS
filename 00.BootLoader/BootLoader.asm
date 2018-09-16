ORG 0x00	; �޸� ���� ������ �˷��ִ� ����
BITS 16	; �� ���α׷��� 16��Ʈ ������ �����͸� ó���ϴ� ���α׷����� �˷��ִ� ����


SECTION .text	; text ���� ����

mov ax, 0xB800  ; 0xB800 ���� ��巹��
mov ds, ax      ; DS ���׸�Ʈ �������Ϳ� ���� ��巹�� �� �� ����

jmp 0x07C0:START   ; CS ���׸�Ʈ �������� 0x07C)�� �����ϸ鼭 START ���̺�� �̵�

START:
	mov ax, 0x07C0 ; 8086 ���μ��������� ���׸�Ʈ�� ���� ���� ���� �� ���� (���� ���� �������͸� �̿�)
	mov ds, ax     ; DS ���׸�Ʈ �������Ϳ� ���� ��巹�� ����

    mov ax, 0xB800  ; ���� �޸� ��巹��
    mov es, ax      ; ES ���׸�Ʈ �������Ϳ� ����

    mov si, 0   ; index �ʱ�ȭ

.SCREENCLEARLOOP:   ; ȭ�� clear �Լ�
    mov byte [ es: si ], 0      ; ���� ����
    mov byte [ es: si + 1], 0x0A   ; �Ӽ� �� ����, ����� ����

    add si, 2

    cmp si, 80 * 24 * 2
    jl .SCREENCLEARLOOP

    ; index �ʱ�ȭ
    mov si, 0
    mov di, 0

.MESSAGELOOP:   ; �޼��� ��� �Լ�
    mov cl, byte [ si + MESSAGE1 ] ; �޼����� ����� �ּҿ��� si �ε����� ���� ������

    cmp cl, 0   ; ���ڿ��� ������ ��
    je .FINISH  ; ���̸� FINISH�� ����

    mov byte[ es: di ], cl ; ���� ���� ���� �޸�(���� es ��������)�� ����

    add si, 1   ; ���ڿ� �ε��� ++
    add di, 2   ; ���� �޸� �ε���++ (���� + �Ӽ� = 2����Ʈ)

    jmp .MESSAGELOOP

.FINISH:
jmp $  ; loop


; ������ ����

MESSAGE1:   db 'MINT64 OS Boot Loader Start~!!', 0 ; ��� �޼���

times 510 - ( $ - $$ )	db	0x00
; $: ���� ������ �ּ�
; $$: ���� ������ ���� �ּ�
; times �ݺ���

db 0x55
db 0xAA
