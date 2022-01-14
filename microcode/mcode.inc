
%define F_C		0x01
%define F_P		0x04
%define F_A		0x10
%define F_Z		0x40
%define F_S		0x80
%define F_T		0x100
%define F_I		0x200
%define F_D		0x400
%define F_O		0x800

%define ALL		0x8D5
%define NOCARRY		0x8D4
%define NOA		0x8C5
%define PSZ		0x0C4

%define AL		0
%define CL		1
%define DL		2
%define BL		3
%define AH		4
%define CH		5
%define DH		6
%define BH		7

%define AX		0
%define CX		1
%define DX		2
%define BX		3
%define SP		4
%define BP		5
%define SI		6
%define DI		7
%define ES		8
%define CS		9
%define SS		10
%define DS		11
%define FS		12
%define GS		13
%define FLAGS		14
%define IP		15

%define END		dw 0x0001, 0
%define HALT		dw 0x0011, 0
%define ENDPREFIX	dw 0x0002, 0
%define MODRM		dw 0x0003, 0
%define SIGNEXT		dw 0x0004, 0
%define JMPTABLE	dw 0x0005, 0
%define SETIOPORT	dw 0x4006, 0
%define DUP		dw 0x8007, 0
%define FETCH8		dw 0x8008, 0
%define FETCH8S		dw 0x8018, 0
%define FETCH16		dw 0x8009, 0
%define DECCX		dw 0x000A, 0
%define STACKLEFT	dw 0x800B, 0
%define NOP		dw 0x000B, 0
%define STACKRIGHT	dw 0x400B, 0
%define STACKSWAP	dw 0xC00B, 0
%define SETREPZ		dw 0x001B, 0
%define SETREPNZ	dw 0x002B, 0
%define HLT		dw 0x004B, 0
%define PUSH		dw 0x400C, 0
%define POP		dw 0x800D, 0
%define ADV_SI		dw 0x001E, 0
%define ADV_DI		dw 0x002E, 0
%define ADV_SIDI	dw 0x003E, 0
%define ADD_IP		dw 0x400F, 0
%define SETOFS		dw 0x4100, 0
%define GETOFS		dw 0x8101, 0
%define SETSEG		dw 0x4102, 0
%define OVERRIDESEG	dw 0x4112, 0
%define GETSEG		dw 0x8103, 0
%define SAVESEG		dw 0x0104, 0
%define SAVESEG_ESDI	dw 0x0114, 0
%define RESTSEG		dw 0x0105, 0
%define MUL		dw 0x0116, 0
%define DIV		dw 0x0126, 0
%define IMUL		dw 0x0146, 0
%define IDIV		dw 0x0186, 0
%define HLT		dw 0x0107, 0
%define READ8		dw 0x8108, 0
%define READ16		dw 0x8109, 0
%define WRITE8		dw 0x410A, 0
%define WRITE16		dw 0x410B, 0
%define READIO8		dw 0x810C, 0
%define WRITEIO8	dw 0x410E, 0
%define LOAD_E8		dw 0x8200, 0
%define LOAD_E16	dw 0x8201, 0
%define STORE_E8	dw 0x4202, 0
%define STORE_E16	dw 0x4203, 0
%define LOAD_G8		dw 0x8204, 0
%define LOAD_G16	dw 0x8205, 0
%define STORE_G8	dw 0x4206, 0
%define STORE_G16	dw 0x4207, 0
%define LOAD_SREG	dw 0x8208, 0
%define STORE_SREG	dw 0x4209, 0

%define ADD8		dw 0x4400, 0
%define ADC8		dw 0x4401, 0
%define SUB8		dw 0x4402, 0
%define SBB8		dw 0x4403, 0
%define AND8		dw 0x4404, 0
%define OR8		dw 0x4405, 0
%define XOR8		dw 0x4406, 0
%define SHL8		dw 0x4407, 0
%define SHR8		dw 0x4408, 0
%define SAR8		dw 0x4409, 0
%define ROL8		dw 0x440A, 0
%define ROR8		dw 0x440B, 0
%define RCL8		dw 0x440C, 0
%define RCR8		dw 0x440D, 0
%define ADD		dw 0x4500, 0
%define ADC		dw 0x4501, 0
%define SUB		dw 0x4502, 0
%define SBB		dw 0x4503, 0
%define AND		dw 0x4504, 0
%define OR		dw 0x4505, 0
%define XOR		dw 0x4506, 0
%define SHL		dw 0x4507, 0
%define SHR		dw 0x4508, 0
%define SAR		dw 0x4509, 0
%define ROL		dw 0x450A, 0
%define ROR		dw 0x450B, 0
%define RCL		dw 0x450C, 0
%define RCR		dw 0x450D, 0

%macro LOADREG8 1
	dw 0x8800 + %1
	dw 0
%endmacro

%macro LOADREG 1
	dw 0x8900 + %1
	dw 0
%endmacro

%macro STOREREG8 1
	dw 0x4A00 + %1
	dw 0
%endmacro

%macro STOREREG 1
	dw 0x4B00 + %1
	dw 0
%endmacro


%macro ADDFLAGS 1
	dw 0x0000 + (%1 & 0x0FFF)
	dw 1
%endmacro

%macro REMOVEFLAGS 1
	dw 0x1000 + (%1 & 0x0FFF)
	dw 1
%endmacro

%macro TESTFLAGS 1
;	dw 0xA000 + (%1 & 0x0FFF)
;	dw 1
	LOADREG FLAGS
	IMM %1
	AND
%endmacro

%macro ALUFLAGS 1
	dw 0x3000 + (%1 & 0x0FFF)
	dw 1
%endmacro

%macro JMP 1
	dw 0x0000 + (%1 - start) / 4
	dw 2
%endmacro

%macro JZ 1
	dw 0xE000 + (%1 - start) / 4
	dw 2
%endmacro

%macro JNZ 1
	dw 0xD000 + (%1 - start) / 4
	dw 2
%endmacro

%macro JREP 1
	dw 0x4000 + (%1 - start) / 4
	dw 2
%endmacro

%macro JREPZ 1
	dw 0x5000 + (%1 - start) / 4
	dw 2
%endmacro

%macro JREPNZ 1
	dw 0x6000 + (%1 - start) / 4
	dw 2
%endmacro


%macro IMM 1
	dw %1
	dw 3
%endmacro

%macro ALU0 4
	MODRM
	LOAD_G8
%if (%4)
	LOADREG FLAGS
	IMM 1
	AND
	ADD8
%endif
	LOAD_E8
	dw 0x4400 + %1, 0
	ALUFLAGS %3
%if (%2)
	STORE_E8
%endif
	END
%endmacro

%macro ALU1 4
	MODRM
	LOAD_G16
%if (%4)
	LOADREG FLAGS
	IMM 1
	AND
	ADD
%endif
	LOAD_E16
	dw 0x4500 + %1, 0
	ALUFLAGS %3
%if (%2)
	STORE_E16
%endif
	END
%endmacro

%macro ALU2 4
	MODRM
	LOAD_E8
%if (%4)
	LOADREG FLAGS
	IMM 1
	AND
	ADD8
%endif
	LOAD_G8
	dw 0x4400 + %1, 0
	ALUFLAGS %3
%if (%2)
	STORE_G8
%endif
	END
%endmacro

%macro ALU3 4
	MODRM
	LOAD_E16
%if (%4)
	LOADREG FLAGS
	IMM 1
	AND
	ADD
%endif
	LOAD_G16
	dw 0x4500 + %1, 0
	ALUFLAGS %3
%if (%2)
	STORE_G16
%endif
	END
%endmacro

%macro ALU4 4
	FETCH8
%if (%4)
	LOADREG FLAGS
	IMM 1
	AND
	ADD8
%endif
	LOADREG8 AL
	dw 0x4400 + %1, 0
	ALUFLAGS %3
%if (%2)
	STOREREG8 AL
%endif
	END
%endmacro

%macro ALU5 4
	FETCH16
%if (%4)
	LOADREG FLAGS
	IMM 1
	AND
	ADD
%endif
	LOADREG AX
	dw 0x4500 + %1, 0
	ALUFLAGS %3
%if (%2)
	STOREREG AX
%endif
	END
%endmacro

%macro ALU 10
i_%1:
	ALU0 %7, %8, %9, %10
i_%2:
	ALU1 %7, %8, %9, %10
i_%3:
	ALU2 %7, %8, %9, %10
i_%4:
	ALU3 %7, %8, %9, %10
i_%5:
	ALU4 %7, %8, %9, %10
i_%6:
	ALU5 %7, %8, %9, %10
%endmacro

%macro INCREG 1
	IMM 1
	LOADREG %1
	ADD
	STOREREG %1
	ALUFLAGS NOCARRY
	END

;	REMOVEFLAGS NOCARRY
;	IMM 1
;	LOADREG %1
;	ADD
;	ALUFLAGS PSZ
;	DUP
;	STOREREG %1
;	DUP
;	IMM 0x8000
;	SUB
;	JNZ inc_%1_skip1
;	ADDFLAGS F_O
;inc_%1_skip1:
;	IMM 0x000F
;	AND
;	JNZ inc_%1_skip2
;	ADDFLAGS F_A
;inc_%1_skip2:
	END
%endmacro

%macro DECREG 1
	IMM 1
	LOADREG %1
	SUB
	ALUFLAGS NOCARRY
	STOREREG %1
;	REMOVEFLAGS NOCARRY
;	IMM 1
;	LOADREG %1
;	SUB
;	ALUFLAGS PSZ
;	DUP
;	STOREREG %1
;	DUP
;	IMM 0x7FFF
;	SUB
;	JNZ dec_%1_skip1
;	ADDFLAGS F_O
;dec_%1_skip1:
;	IMM 0x000F
;	AND
;	IMM 0x000F
;	SUB
;	JNZ dec_%1_skip2
;	ADDFLAGS F_A
;dec_%1_skip2:
	END
%endmacro

%macro JCOND 1
	FETCH8S
	TESTFLAGS %1
	JZ done
	ADD_IP
	; LOADREG IP
	; ADD
	; STOREREG IP
	END
%endmacro

%macro JNCOND 1
	FETCH8S
	TESTFLAGS %1
	JNZ done
	ADD_IP
	; LOADREG IP
	; ADD
	; STOREREG IP
	END
%endmacro

%macro XCHGREG 1
	LOADREG %1
	LOADREG AX
	STOREREG %1
	STOREREG AX
	END
%endmacro

start:
	JMP i_00
	JMP i_01
	JMP i_02
	JMP i_03
	JMP i_04
	JMP i_05
	JMP i_06
	JMP i_07
	JMP i_08
	JMP i_09
	JMP i_0A
	JMP i_0B
	JMP i_0C
	JMP i_0D
	JMP i_0E
	JMP i_0F
	JMP i_10
	JMP i_11
	JMP i_12
	JMP i_13
	JMP i_14
	JMP i_15
	JMP i_16
	JMP i_17
	JMP i_18
	JMP i_19
	JMP i_1A
	JMP i_1B
	JMP i_1C
	JMP i_1D
	JMP i_1E
	JMP i_1F
	JMP i_20
	JMP i_21
	JMP i_22
	JMP i_23
	JMP i_24
	JMP i_25
	JMP i_26
	JMP i_27
	JMP i_28
	JMP i_29
	JMP i_2A
	JMP i_2B
	JMP i_2C
	JMP i_2D
	JMP i_2E
	JMP i_2F
	JMP i_30
	JMP i_31
	JMP i_32
	JMP i_33
	JMP i_34
	JMP i_35
	JMP i_36
	JMP i_37
	JMP i_38
	JMP i_39
	JMP i_3A
	JMP i_3B
	JMP i_3C
	JMP i_3D
	JMP i_3E
	JMP i_3F
	JMP i_40
	JMP i_41
	JMP i_42
	JMP i_43
	JMP i_44
	JMP i_45
	JMP i_46
	JMP i_47
	JMP i_48
	JMP i_49
	JMP i_4A
	JMP i_4B
	JMP i_4C
	JMP i_4D
	JMP i_4E
	JMP i_4F
	JMP i_50
	JMP i_51
	JMP i_52
	JMP i_53
	JMP i_54
	JMP i_55
	JMP i_56
	JMP i_57
	JMP i_58
	JMP i_59
	JMP i_5A
	JMP i_5B
	JMP i_5C
	JMP i_5D
	JMP i_5E
	JMP i_5F
	JMP i_60
	JMP i_61
	JMP i_62
	JMP i_63
	JMP i_64
	JMP i_65
	JMP i_66
	JMP i_67
	JMP i_68
	JMP i_69
	JMP i_6A
	JMP i_6B
	JMP i_6C
	JMP i_6D
	JMP i_6E
	JMP i_6F
	JMP i_70
	JMP i_71
	JMP i_72
	JMP i_73
	JMP i_74
	JMP i_75
	JMP i_76
	JMP i_77
	JMP i_78
	JMP i_79
	JMP i_7A
	JMP i_7B
	JMP i_7C
	JMP i_7D
	JMP i_7E
	JMP i_7F
	JMP i_80
	JMP i_81
	JMP i_82
	JMP i_83
	JMP i_84
	JMP i_85
	JMP i_86
	JMP i_87
	JMP i_88
	JMP i_89
	JMP i_8A
	JMP i_8B
	JMP i_8C
	JMP i_8D
	JMP i_8E
	JMP i_8F
	JMP i_90
	JMP i_91
	JMP i_92
	JMP i_93
	JMP i_94
	JMP i_95
	JMP i_96
	JMP i_97
	JMP i_98
	JMP i_99
	JMP i_9A
	JMP i_9B
	JMP i_9C
	JMP i_9D
	JMP i_9E
	JMP i_9F
	JMP i_A0
	JMP i_A1
	JMP i_A2
	JMP i_A3
	JMP i_A4
	JMP i_A5
	JMP i_A6
	JMP i_A7
	JMP i_A8
	JMP i_A9
	JMP i_AA
	JMP i_AB
	JMP i_AC
	JMP i_AD
	JMP i_AE
	JMP i_AF
	JMP i_B0
	JMP i_B1
	JMP i_B2
	JMP i_B3
	JMP i_B4
	JMP i_B5
	JMP i_B6
	JMP i_B7
	JMP i_B8
	JMP i_B9
	JMP i_BA
	JMP i_BB
	JMP i_BC
	JMP i_BD
	JMP i_BE
	JMP i_BF
	JMP i_C0
	JMP i_C1
	JMP i_C2
	JMP i_C3
	JMP i_C4
	JMP i_C5
	JMP i_C6
	JMP i_C7
	JMP i_C8
	JMP i_C9
	JMP i_CA
	JMP i_CB
	JMP i_CC
	JMP i_CD
	JMP i_CE
	JMP i_CF
	JMP i_D0
	JMP i_D1
	JMP i_D2
	JMP i_D3
	JMP i_D4
	JMP i_D5
	JMP i_D6
	JMP i_D7
	JMP i_D8
	JMP i_D9
	JMP i_DA
	JMP i_DB
	JMP i_DC
	JMP i_DD
	JMP i_DE
	JMP i_DF
	JMP i_E0
	JMP i_E1
	JMP i_E2
	JMP i_E3
	JMP i_E4
	JMP i_E5
	JMP i_E6
	JMP i_E7
	JMP i_E8
	JMP i_E9
	JMP i_EA
	JMP i_EB
	JMP i_EC
	JMP i_ED
	JMP i_EE
	JMP i_EF
	JMP i_F0
	JMP i_F1
	JMP i_F2
	JMP i_F3
	JMP i_F4
	JMP i_F5
	JMP i_F6
	JMP i_F7
	JMP i_F8
	JMP i_F9
	JMP i_FA
	JMP i_FB
	JMP i_FC
	JMP i_FD
	JMP i_FE
	JMP i_FF
