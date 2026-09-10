// returns 0 -> library not initialized
// otherwise returns width and height respectively 
unsigned short getwidth(void);
unsigned short getheight(void);

// returns 0 -> success
// returns 1 -> invalid fd
// returns 2 -> terminal too small
// returns 3 -> could not allocate memory
int initscr(void);

void endscr(void);

int addch(unsigned short y, unsigned short x, unsigned char ch);

void clear(void);

int refresh(void);
