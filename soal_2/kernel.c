// kernel.c - Kernel utama 16-bit
// Fitur: check, add, sub, fac, season, triangle, clear, help

// Deklarasi fungsi dari kernel.asm
void _putChar(char c);
char _getChar();
void _clearScreen();
void _setColor(char color);

// Warna untuk season
#define COLOR_WHITE   0x07
#define COLOR_CYAN    0x03
#define COLOR_GREEN   0x02
#define COLOR_YELLOW  0x06
#define COLOR_MAGENTA 0x05
#define COLOR_RED     0x04

// ============================================================
// Fungsi helper dasar
// ============================================================

void print(const char *str) {
    while (*str) {
        _putChar(*str++);
    }
}

void println(const char *str) {
    print(str);
    _putChar('\r');
    _putChar('\n');
}

// Konversi integer ke string
void printInt(int n) {
    char buf[10];
    int i = 0;
    if (n < 0) {
        _putChar('-');
        n = -n;
    }
    if (n == 0) {
        _putChar('0');
        return;
    }
    while (n > 0) {
        buf[i++] = '0' + (n % 10);
        n /= 10;
    }
    // Reverse
    for (int j = i - 1; j >= 0; j--) {
        _putChar(buf[j]);
    }
}

// Konversi string ke integer
int strToInt(const char *str) {
    int result = 0;
    int neg = 0;
    if (*str == '-') { neg = 1; str++; }
    while (*str >= '0' && *str <= '9') {
        result = result * 10 + (*str - '0');
        str++;
    }
    return neg ? -result : result;
}

// Bandingkan dua string
int strCmp(const char *a, const char *b) {
    while (*a && *b && *a == *b) { a++; b++; }
    return *a - *b;
}

// Salin string
void strCpy(char *dst, const char *src) {
    while (*src) *dst++ = *src++;
    *dst = 0;
}

// Panjang string
int strLen(const char *str) {
    int len = 0;
    while (*str++) len++;
    return len;
}

// ============================================================
// Baca input dari keyboard
// ============================================================

void readLine(char *buf, int max) {
    int i = 0;
    char c;
    while (i < max - 1) {
        c = _getChar();
        if (c == '\r' || c == '\n') break;
        if (c == '\b' && i > 0) {
            // Backspace
            i--;
            _putChar('\b');
            _putChar(' ');
            _putChar('\b');
            continue;
        }
        buf[i++] = c;
        _putChar(c);  // Echo karakter
    }
    buf[i] = 0;
    _putChar('\r');
    _putChar('\n');
}

// Parse command dan argumen
// Contoh: "add 5 3" -> cmd="add", args[0]="5", args[1]="3"
int parseCmd(char *input, char *cmd, char args[][16], int maxArgs) {
    int i = 0, argCount = 0;

    // Ambil command
    while (input[i] && input[i] != ' ') {
        cmd[i] = input[i];
        i++;
    }
    cmd[i] = 0;

    // Ambil argumen
    while (input[i] && argCount < maxArgs) {
        while (input[i] == ' ') i++;  // Skip spasi
        if (!input[i]) break;
        int j = 0;
        while (input[i] && input[i] != ' ') {
            args[argCount][j++] = input[i++];
        }
        args[argCount][j] = 0;
        argCount++;
    }
    return argCount;
}

// ============================================================
// Implementasi fitur-fitur
// ============================================================

// check - cek apakah sistem berjalan
void cmd_check() {
    println("ok");
}

// add - penjumlahan dua angka
void cmd_add(int a, int b) {
    printInt(a + b);
    _putChar('\r');
    _putChar('\n');
}

// sub - pengurangan dua angka
void cmd_sub(int a, int b) {
    printInt(a - b);
    _putChar('\r');
    _putChar('\n');
}

// fac - faktorial (16-bit, max ~8 sebelum overflow)
void cmd_fac(int n) {
    // 16-bit signed max = 32767
    // 8! = 40320 > 32767, jadi limit di 7
    if (n < 0) {
        println("know your limit little bro.");
        return;
    }
    int result = 1;
    for (int i = 1; i <= n; i++) {
        result *= i;
        // Cek overflow 16-bit
        if (result > 32767 || result < 0) {
            println("know your limit little bro.");
            return;
        }
    }
    printInt(result);
    _putChar('\r');
    _putChar('\n');
}

// season - ganti warna teks
void cmd_season(const char *season) {
    if (strCmp(season, "winter") == 0) {
        _setColor(COLOR_CYAN);
        println("winter mode");
    } else if (strCmp(season, "spring") == 0) {
        _setColor(COLOR_GREEN);
        println("spring mode");
    } else if (strCmp(season, "summer") == 0) {
        _setColor(COLOR_YELLOW);
        println("summer mode");
    } else if (strCmp(season, "fall") == 0) {
        _setColor(COLOR_RED);
        println("fall mode");
    } else if (strCmp(season, "radiant") == 0) {
        _setColor(COLOR_MAGENTA);
        println("radiant mode");
    } else {
        println("Unknown season. Use: winter, spring, summer, fall, radiant");
    }
}

// triangle - cetak segitiga dari 'x'
void cmd_triangle(int n) {
    for (int i = 1; i <= n; i++) {
        for (int j = 0; j < i; j++) {
            _putChar('x');
        }
        _putChar('\r');
        _putChar('\n');
    }
}

// clear - bersihkan layar dan hapus history
void cmd_clear() {
    _clearScreen();
}

// help - tampilkan daftar command
void cmd_help() {
    println("Commands available:");
    println("  check          - check if system is running");
    println("  add  <a> <b>   - addition");
    println("  sub  <a> <b>   - subtraction");
    println("  fac  <n>       - factorial");
    println("  season <name>  - change color (winter/spring/summer/fall/radiant)");
    println("  triangle <n>   - print triangle");
    println("  clear          - clear screen");
    println("  help           - show this help");
}

// ============================================================
// Main kernel loop
// ============================================================

void kernel_main() {
    _clearScreen();
    println("Welcome to Assistant's Last Gift");
    println("type 'help'");
    println("");

    char input[64];
    char cmd[16];
    char args[4][16];

    while (1) {
        print("> ");
        readLine(input, 64);

        if (strLen(input) == 0) continue;

        int argCount = parseCmd(input, cmd, args, 4);

        if (strCmp(cmd, "check") == 0) {
            cmd_check();
        } else if (strCmp(cmd, "add") == 0 && argCount >= 2) {
            cmd_add(strToInt(args[0]), strToInt(args[1]));
        } else if (strCmp(cmd, "sub") == 0 && argCount >= 2) {
            cmd_sub(strToInt(args[0]), strToInt(args[1]));
        } else if (strCmp(cmd, "fac") == 0 && argCount >= 1) {
            cmd_fac(strToInt(args[0]));
        } else if (strCmp(cmd, "season") == 0 && argCount >= 1) {
            cmd_season(args[0]);
        } else if (strCmp(cmd, "triangle") == 0 && argCount >= 1) {
            cmd_triangle(strToInt(args[0]));
        } else if (strCmp(cmd, "clear") == 0) {
            cmd_clear();
        } else if (strCmp(cmd, "help") == 0) {
            cmd_help();
        } else {
            print("Unknown command: ");
            println(cmd);
        }
    }
}