DA_32		EQU	0x4000
DA_DPL3		EQU	  0x60
DA_DRW		EQU	0x92
DA_CR		EQU	0x9A
SA_RPL3		EQU	3
DA_LIMIT_4K	EQU	0x8000
PG_P		EQU	1
PG_RWW		EQU	2
PG_USU		EQU	4

%macro Descriptor 3
	dw	%2 & 0xFFFF
	dw	%1 & 0xFFFF
	db	(%1 >> 16) & 0xFF
	dw	((%2 >> 8) & 0xF00) | (%3 & 0xF0FF)
	db	(%1 >> 24) & 0xFF
%endmacro
%macro Gate 4
	dw	(%2 & 0xFFFF)
	dw	%1
	dw	(%3 & 0x1F) | ((%4 << 8) & 0xFF00)
	dw	((%2 >> 16) & 0xFFFF)
%endmacro
