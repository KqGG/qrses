#include "../inc/qrses.h"

long int read(int fd, void *buf, unsigned long int count);
int nanosleep(long int sec, long int nsec);

int main(void) {
	int ret = initscr();
	if (ret != 0) return ret;
	
	addch(0, 0, 'a');
	addch(0, 10, 'b');
	addch(5, 0, 'c');
	addch(5, 10, 'd');

	addch(getheight(), getwidth(), 'x');

	refresh();

	nanosleep(2, 0);

	endscr();
	return 0;
}
