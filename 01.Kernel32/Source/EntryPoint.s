[ORG 0x00]              ; �޸� ���� ������ �˷��ִ� ����
[BITS 16]               ; �� ���α׷��� 16��Ʈ ������ �����͸� ó���ϴ� ���α׷����� �˷��ִ� ����

SECTION .text           ; text ���� ����

; �ڵ� ����
START:
    mov ax, 0x1000      ; ��ȣ����� ���� �ּҸ� ���׸�Ʈ �������Ϳ� ����
    mov ds, ax
    mov es, ax

    cli                 ; ���ͷ�Ʈ�� �߻����� ���ϵ��� ����
    lgdt [ GDTR ]       ; GDTR �ڷᱸ���� ���μ����� �����Ͽ� GDT ���̺� �ε�

    ; ��ȣ��� ����
    mov eax, 0x4000003B    ; PG=0, CD=1, NW=0, AM=0, WP=0, NE=1, ET=1, TS=1, EM=0, MP=1, PE=1
    mov cr0, eax           ; CR0 ��Ʈ�� �������Ϳ� ������ ������ �÷��׸� �����Ͽ� ��ȣ ���� ��ȯ

    ; Ŀ�� �ڵ� ���׸�Ʈ�� 0x00 �������� �ϴ� ������ ��ü�ϰ� EIP�� ���� 0x00�� �������� �缳��
    ; CS ���׸�Ʈ ������ : EIP
    jmp dword 0x08: ( PROTECTEDMODE - $$ + 0x10000 )

    [BITS 32]
    PROTECTEDMODE:
        mov ax, 0x10    ; ��ȣ��� Ŀ�ο� ������ ���׸�Ʈ ��ũ���� ����
        mov ds, ax      ; DS ���׸�Ʈ �����Ϳ� ����
        mov es, ax      ; ES ���׸�Ʈ �����Ϳ� ����
        mov fs, ax      ; FS ���׸�Ʈ �����Ϳ� ����
        mov gs, ax      ; GS ���׸�Ʈ �����Ϳ� ����

        ; ������ 0x00000000 ~ 0x0000FFFF ������ 64KB ũ��� ����
        mov ss, ax      ; SS ���׸�Ʈ �����Ϳ� ����
        mov esp, 0xFFFE
        mov ebp, 0xFFFE

        ; ȭ�鿡 ��ȣ ���� ��ȯ�Ǿ��ٴ� �޽����� ����
        push ( SWITCHSUCCESSMESSAGE - $$ + 0x10000 )    ; ����� �޽����� ��巹���� ���ÿ� ����
        push 2
        push 0
        call PRINTMESSAGE
        add esp, 12         ; �Ķ���� ����

        jmp $

    ; �Լ� �ڵ� ����
    ; �޽��� ��� �Լ� (32��Ʈ)
    PRINTMESSAGE:
        push ebp
        mov ebp, esp
        push esi
        push edi
        push eax
        push ecx
        push edx

        ;=================================
        ; X ,Y�� ��ǥ�� ���� �޸��� ��巹���� ����
        ;=================================
        mov eax, dword [ ebp + 12 ]   ; 2��° �Ķ���� ����(y ��ǥ) eax�� ����
        mov esi, 160                ; �� ������ ����Ʈ�� ( 80(���ι��ڰ���) * 2(���ڰ�+�Ӽ�) )
        mul esi                     ; �Ķ���� ���� ���Ͽ� y ��ǥ ���
        mov edi, eax                ; edi �������Ϳ� y��ǥ�� ����

        mov eax, dword [ ebp + 8 ]   ; 1��° �Ķ���� ���� (x ��ǥ)
        mov esi, 2                  ; ������ ����Ʈ �� (���ڰ�+�Ӽ�)
        mul esi                     ; �Ķ���� ���� ���Ͽ� x ��ǥ ���
        add edi, eax                ; y��ǥ���� ���Ͽ� ���� �޸� ��巹�� ���

        mov esi, dword [ ebp + 16 ]  ; esi �������Ϳ� ����� ���ڿ� �ּ� ����

    .MESSAGELOOP:   ; �޼��� ��� �Լ�
        mov cl, byte [ esi ]        ; �޼����� ����� �ּҿ��� esi �ε����� ���� ������

        cmp cl, 0                   ; ���ڿ��� ������ ��
        je .MESSAGEEND              ; ���̸� MESSAGEEND�� ����

        mov byte [ edi + 0xB8000 ], cl ; ���� ���� ���� �޸𸮿� ����

        add esi, 1   ; ���ڿ� �ε��� ++
        add edi, 2   ; ���� �޸� �ε���++ (���� + �Ӽ� = 2����Ʈ)

        jmp .MESSAGELOOP

    .MESSAGEEND:
        ; 6���� �������� �� ���ÿ� �ӽ� ���� FILO ������ �������� POP
        pop edx
        pop ecx
        pop eax
        pop edi
        pop esi
        pop ebp     ; ���̽� ������ ����
        ret         ; ret = pop eip, jmp eip

    ; ������ ����
    align 8, db 0

    dw 0x0000
    ; GDTR �ڷᱸ�� ����
    GDTR:
        dw GDTEND - GDT - 1         ; �Ʒ��� ��ġ�ϴ� GDT ���̺��� ��ü ũ��
        dd ( GDT - $$ + 0x10000 )   ; �Ʒ��� ��ġ�ϴ� GDT ���̺��� ���� ��巹��

    ; GDT ���̺� ����
    GDT:
        ; �� ��ũ����. 0���� �ʱ�ȭ �Ͽ��� ��
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

        ; ��ȣ ��� Ŀ�ο� ������ ���׸�Ʈ ��ũ����
        DATADESCRIPTOR:
            dw 0xFFFF   ; Limit [15:0]
            dw 0x0000   ; Base [15:0]
            db 0x00     ; Base [23:16]
            db 0x92     ; P=1, DPL=0, Data Segment, Read/Write
            db 0xCF     ; G=1, D=1, L=0, Limit [19:16]
            db 0x00     ; Base [31:24]
    GDTEND:

    ; ��ȣ ��� ��ȯ �޽���
    SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success~!!', 0

    times 512 - ( $ - $$ ) db 0x00
