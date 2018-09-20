[ORG 0x00]  ; 메모리 시작 번지를 알려주는 선언문
[BITS 16]   ; 이 프로그램이 16비트 단위로 데이터를 처리하는 프로그램임을 알려주는 선언문

SECTION .text   ; text 섹션 정의

jmp 0x1000:START   ; CS 세그먼트 레지스터 0x1000을 복사하면서 START 레이블로 이동

SECTORCOUNT:        dw 0x0000   ; 현재 실행 중인 섹터 번호를 저장
TOTALSECTORCOUNT:   equ 1024    ; 가상 OS 총 섹터 수

; 코드영역
START:
    mov ax, cs      ; CS 세그 먼트 값을 AX에 설정
    mov ds, ax      ; DS 세그먼트 값에  CS 값 설정
    mov ax, 0xB800
    mov es, ax      ; ES 세그먼트에 비디오 어드레스 값 설정

    ; 각 섹터 별로 코드 생성
    %assign i   0           ; i 변수 = 섹터 번호
    %rep TOTALSECTORCOUNT   ; nasm 전처리문, 저장된 값만큼 반복
        %assign i   i + 1     ; i = i + 1

        ; 현재 실행 중인 코드가 포함된 섹터의 위치를 화면 좌표로 변환
        mov ax, 2                   ; 비디오 메모리에서 사용하는 문자크기(2바이트)를  AX에 설정
        mul word [ SECTORCOUNT ]    ; AX값과 섹터 수와 곱함
        mov si, ax                  ; si에 결과값 저장

        ; 계산된 결과(si)를 비디오 메모리에 오프셋으로 삼아 세 번째 라인부터 화면에 0을 출력
        mov byte [ es: si + ( 160 * 2 ) ], '0' + ( i % 10 )
        add word [ SECTORCOUNT ], 1

        ; 마지막 섹터면 무한 루프 상태로 점프
        %if i == TOTALSECTORCOUNT
            jmp $
        %else
            ; 0x20 ( 512바이트 씩 점프 )
            jmp ( 0x1000 + i * 0x20 ): 0x0000 ; 다음섹터 오프셋으로 이동
        %endif

        ; 섹터값을 전부 0으로 채움
        times ( 512 - ( $ - $$ ) % 512 )  db 0x00

    %endrep
