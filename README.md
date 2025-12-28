# 32-Bit Profesyonel ALU Tasarımı

## Teknik Dokümantasyon Raporu

**Proje Adı:** 32-Bit Aritmetik Mantık Birimi (ALU)  
**Tasarım Dili:** VHDL (VHSIC Hardware Description Language)  
**Versiyon:** 1.0  
**Tarih:** Aralık 2024

---

## 1. Özet

Bu rapor, profesyonel seviyede tasarlanmış 32-bit genişliğinde bir Aritmetik Mantık Birimi'nin (ALU) teknik detaylarını sunmaktadır. Tasarlanan ALU, 16 farklı aritmetik ve mantıksal işlemi desteklemekte olup, kapsamlı durum bayrakları (status flags) üretmektedir. Senkron tasarım prensiplerine uygun olarak geliştirilmiştir.

---

## 2. Tasarım Özellikleri

### 2.1 Genel Spesifikasyonlar

| Parametre | Değer |
|-----------|-------|
| Veri Genişliği | 32-bit |
| Operasyon Sayısı | 16 |
| Opcode Genişliği | 4-bit |
| Shift Miktarı Genişliği | 5-bit |
| Tasarım Tipi | Senkron (Clock-driven) |
| Reset Tipi | Aktif-düşük asenkron reset |
| Standart | IEEE 1076-2008 (VHDL-2008) |

### 2.2 Port Tanımlamaları

```
┌─────────────────────────────────────────────────────────────────┐
│                           ALU Entity                             │
├─────────────────────────────────────────────────────────────────┤
│  INPUTS                          │  OUTPUTS                      │
│  ────────                        │  ─────────                    │
│  clk        [1-bit]              │  result       [32-bit]        │
│  rst_n      [1-bit]              │  result_hi    [32-bit]        │
│  enable     [1-bit]              │  flag_zero    [1-bit]         │
│  operand_a  [32-bit]             │  flag_carry   [1-bit]         │
│  operand_b  [32-bit]             │  flag_overflow[1-bit]         │
│  opcode     [4-bit]              │  flag_negative[1-bit]         │
│  shift_amt  [5-bit]              │  flag_parity  [1-bit]         │
│                                  │  valid_out    [1-bit]         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Desteklenen Operasyonlar

### 3.1 Operasyon Tablosu

| Opcode | Mnemonik | İşlem | Matematiksel İfade |
|--------|----------|-------|-------------------|
| 0000 | ADD | Toplama | Result = A + B |
| 0001 | SUB | Çıkarma | Result = A - B |
| 0010 | AND | Bitwise AND | Result = A ∧ B |
| 0011 | OR | Bitwise OR | Result = A ∨ B |
| 0100 | XOR | Bitwise XOR | Result = A ⊕ B |
| 0101 | NOT | Bitwise NOT | Result = ¬A |
| 0110 | NAND | Bitwise NAND | Result = ¬(A ∧ B) |
| 0111 | NOR | Bitwise NOR | Result = ¬(A ∨ B) |
| 1000 | SLL | Shift Left Logical | Result = A << n |
| 1001 | SRL | Shift Right Logical | Result = A >> n |
| 1010 | SRA | Shift Right Arithmetic | Result = A >>> n |
| 1011 | ROL | Rotate Left | Result = A ↻ n |
| 1100 | ROR | Rotate Right | Result = A ↺ n |
| 1101 | INC | Increment | Result = A + 1 |
| 1110 | DEC | Decrement | Result = A - 1 |
| 1111 | CMP | Compare | Flags = A - B |

### 3.2 Operasyon Kategorileri

```
                    ALU Operasyonları
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   Aritmetik          Mantıksal        Kaydırma/Döndürme
        │                 │                 │
   ┌────┴────┐       ┌────┴────┐       ┌────┴────┐
   │ADD      │       │AND      │       │SLL      │
   │SUB      │       │OR       │       │SRL      │
   │INC      │       │XOR      │       │SRA      │
   │DEC      │       │NOT      │       │ROL      │
   │CMP      │       │NAND     │       │ROR      │
   └─────────┘       │NOR      │       └─────────┘
                     └─────────┘
```

---

## 4. Durum Bayrakları (Status Flags)

### 4.1 Bayrak Açıklamaları

| Bayrak | Açıklama | Tetikleme Koşulu |
|--------|----------|------------------|
| **Zero (Z)** | Sonuç sıfır mı? | Result = 0x00000000 |
| **Carry (C)** | Taşma oluştu mu? | Unsigned overflow |
| **Overflow (V)** | İşaretli taşma | Signed overflow |
| **Negative (N)** | Sonuç negatif mi? | Result[31] = '1' |
| **Parity (P)** | Çift parite | XOR of all bits |

### 4.2 Overflow Algılama Mantığı

İşaretli sayılarda overflow tespiti için kullanılan formül:

**ADD için:**
```
Overflow = (A[31] ∧ B[31] ∧ ¬R[31]) ∨ (¬A[31] ∧ ¬B[31] ∧ R[31])
```

**SUB için:**
```
Overflow = (A[31] ∧ ¬B[31] ∧ ¬R[31]) ∨ (¬A[31] ∧ B[31] ∧ R[31])
```

Bu formüller, iki pozitif sayının toplamının negatif veya iki negatif sayının toplamının pozitif olması durumlarını tespit eder.

---

## 5. Mimari Tasarım

### 5.1 Blok Diyagramı

```
                    ┌──────────────────────────────────────────────┐
                    │                   ALU Core                    │
                    │                                               │
    operand_a ──────┤►┌─────────────┐                               │
     [32-bit]       │ │             │      ┌─────────────┐          │
                    │ │  Arithmetic │──────►             │          │
    operand_b ──────┤►│    Unit     │      │             │          │
     [32-bit]       │ └─────────────┘      │   Output    │          │
                    │                      │   MUX       ├──────────┼──► result
                    │ ┌─────────────┐      │  (4-bit     │          │    [32-bit]
    operand_a ──────┤►│             │──────►  select)    │          │
                    │ │   Logic     │      │             │          │
    operand_b ──────┤►│    Unit     │      │             │          │
                    │ └─────────────┘      └──────┬──────┘          │
                    │                             │                 │
                    │ ┌─────────────┐             │                 │
    operand_a ──────┤►│   Shift/    │─────────────┘                 │
                    │ │   Rotate    │                               │
    shift_amt ──────┤►│    Unit     │      ┌─────────────┐          │
     [5-bit]        │ └─────────────┘      │   Flag      ├──────────┼──► flags
                    │                      │  Generator  │          │    [5-bit]
      opcode ───────┤►─────────────────────┤             │          │
     [4-bit]        │                      └─────────────┘          │
                    │                                               │
         clk ───────┤►                                              │
       rst_n ───────┤►                        Register Stage        │
      enable ───────┤►                                              │
                    └──────────────────────────────────────────────┘
```

### 5.2 Veri Akışı

```
          ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
 Inputs   │  Input  │     │   ALU   │     │  Flag   │     │ Output  │
─────────►│ Capture │────►│  Logic  │────►│  Calc   │────►│ Register│────► Outputs
          │ (combo) │     │ (combo) │     │ (combo) │     │  (seq)  │
          └─────────┘     └─────────┘     └─────────┘     └─────────┘
                                  │
                                  ▼
                          ┌─────────────┐
                          │   Opcode    │
                          │   Decoder   │
                          └─────────────┘
```

---

## 6. Proje Dosya Yapısı

```
VHDL/
├── alu_pkg.vhd           # Paket: Tipler, sabitler, fonksiyonlar
├── alu.vhd               # Ana ALU entity ve architecture
├── alu_tb.vhd            # Kapsamlı testbench
└── ALU_Technical_Report.md  # Bu dokümantasyon
```

### 6.1 Dosya Açıklamaları

| Dosya | Satır Sayısı | Açıklama |
|-------|--------------|----------|
| `alu_pkg.vhd` | ~200 | Sabitler, tip tanımlamaları, barrel shifter fonksiyonları |
| `alu.vhd` | ~220 | Ana ALU modülü, tüm işlemler |
| `alu_tb.vhd` | ~400 | Self-checking testbench |

---

## 7. Shift ve Rotate Operasyonları

### 7.1 Shift Left Logical (SLL)

```
Önce:   [b31 b30 b29 ... b2 b1 b0]
Sonra:  [b27 b26 b25 ... 0  0  0  0]  (4-bit shift)

En yüksek değerli 4 bit kaybolur
En düşük değerli 4 bit 0 ile doldurulur
```

### 7.2 Shift Right Logical (SRL)

```
Önce:   [b31 b30 b29 ... b2 b1 b0]
Sonra:  [0   0   0   0  b31 b30 ... b4]  (4-bit shift)

En düşük değerli 4 bit kaybolur
En yüksek değerli 4 bit 0 ile doldurulur
```

### 7.3 Shift Right Arithmetic (SRA)

```
Önce:   [1   b30 b29 ... b2 b1 b0]  (negatif sayı)
Sonra:  [1   1   1   1  1  b30 ... b4]  (4-bit shift)

Sign bit korunur ve genişletilir
```

### 7.4 Rotate Left (ROL)

```
Önce:   [b31 b30 b29 b28 | b27 ... b1 b0]
Sonra:  [b27 ... b1 b0 | b31 b30 b29 b28]  (4-bit rotate)

Yüksek bitler düşük bitlere taşınır
```

### 7.5 Rotate Right (ROR)

```
Önce:   [b31 ... b4 | b3 b2 b1 b0]
Sonra:  [b3 b2 b1 b0 | b31 ... b4]  (4-bit rotate)

Düşük bitler yüksek bitlere taşınır
```

---

## 8. Test Stratejisi

### 8.1 Test Senaryoları

Testbench aşağıdaki kategorilerde testler içermektedir:

1. **Fonksiyonel Testler**
   - Her operasyon için temel doğrulama
   - Beklenen sonuç ile karşılaştırma

2. **Boundary Value Testleri**
   - Minimum değerler (0x00000000)
   - Maximum değerler (0xFFFFFFFF)
   - Sınır geçişleri

3. **Flag Testleri**
   - Zero flag doğrulaması
   - Carry flag doğrulaması
   - Overflow flag doğrulaması
   - Negative flag doğrulaması

4. **Edge Case Testleri**
   - ADD overflow
   - SUB underflow
   - Signed overflow
   - Self-XOR (identity property)

### 8.2 Self-Checking Mechanism

```vhdl
procedure check_result(
    signal passed      : inout integer;
    signal failed      : inout integer;
    constant test_name : string;
    constant expected  : std_logic_vector;
    constant actual    : std_logic_vector
);
```

Testbench sonunda toplam PASS/FAIL sayısı raporlanır.

---

## 9. Simülasyon Komutları

### 9.1 GHDL ile Simülasyon

```bash
# 1. Analiz (Compile)
ghdl -a --std=08 alu_pkg.vhd
ghdl -a --std=08 alu.vhd
ghdl -a --std=08 alu_tb.vhd

# 2. Elaboration
ghdl -e --std=08 alu_tb

# 3. Simulation
ghdl -r --std=08 alu_tb --wave=alu_sim.ghw --stop-time=1000ns

# 4. Waveform Görüntüleme (opsiyonel)
gtkwave alu_sim.ghw
```

### 9.2 ModelSim ile Simülasyon

```tcl
vlib work
vcom -2008 alu_pkg.vhd
vcom -2008 alu.vhd
vcom -2008 alu_tb.vhd
vsim -t 1ns work.alu_tb
add wave -radix hex /*
run 1000ns
```

### 9.3 Vivado ile Simülasyon

```tcl
create_project alu_project ./alu_project -part xc7a35tcpg236-1
add_files {alu_pkg.vhd alu.vhd alu_tb.vhd}
set_property top alu_tb [get_filesets sim_1]
launch_simulation
run 1000ns
```

---

## 10. Zamanlama Analizi

### 10.1 Kritik Yol

```
                    Estimated Critical Path
                    
operand_a/b ──► Adder/Subtractor ──► Result MUX ──► Flag Calculator ──► Output Register
    │                               │
    └── ~3-4 LUT delays ────────────┘                    ~2 LUT delays
    
Toplam: ~5-6 LUT seviyesi
```

### 10.2 Tahmini Performans

| FPGA Ailesi | Tahmini Fmax | Notlar |
|-------------|--------------|--------|
| Artix-7 | ~150-200 MHz | Typical speed grade |
| Kintex-7 | ~200-250 MHz | Better speed grade |
| Spartan-6 | ~100-150 MHz | Older technology |

### 10.3 Kaynak Kullanımı Tahmini

| Kaynak | Tahmini Kullanım | Notlar |
|--------|------------------|--------|
| LUTs | ~150-200 | Logic implementation |
| FFs | ~70-80 | Output registers, flags |
| Carry Chain | 32-bit | For adder/subtractor |

---

## 11. Genişletme Önerileri

### 11.1 Olası Geliştirmeler

1. **Çarpma İşlemi (MUL)**
   - Booth algoritması ile çarpan ekleme
   - result_hi çıkışı yüksek 32-bit için kullanılabilir

2. **Bölme İşlemi (DIV)**
   - Restoring veya non-restoring division
   - Birden fazla cycle gerektirir

3. **Leading Zero Count (LZC)**
   - Floating-point normalizasyon için

4. **Population Count (POPCNT)**
   - Seçim algoritmaları için

### 11.2 Pipeline Eklemek

Performans artırımı için 2-stage pipeline önerilebilir:

```
Stage 1: Opcode decode + operand capture
Stage 2: ALU operation + flag generation
```

---

## 12. Sonuç

Bu raporda sunulan 32-bit ALU tasarımı, modern işlemci ve dijital sistem tasarımlarında kullanılabilecek profesyonel kalitede bir modüldür. Tasarım özellikleri:

- 16 farklı operasyon desteği
- Kapsamlı flag üretimi
- Modüler ve genişletilebilir yapı
- Self-checking testbench ile doğrulama
- Endüstri standardı VHDL-2008 uyumluluğu

---

## Referanslar

1. IEEE Standard VHDL Language Reference Manual (IEEE Std 1076-2008)
2. Pong P. Chu, "RTL Hardware Design Using VHDL"
3. Volnei A. Pedroni, "Circuit Design and Simulation with VHDL"
4. David Money Harris, "Digital Design and Computer Architecture"

---

**Hazırlayan:** Professional VHDL Design  
**Revizyon:** 1.0  
**Lisans:** MIT License
