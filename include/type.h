#ifndef	TYPE_H_
#define	TYPE_H_


typedef	unsigned int		u32;
typedef	unsigned short		u16;
typedef	unsigned char		u8;

typedef	void	(*int_handler)	();
typedef void (*task)();
typedef void (*irq_handler)(int irq);


#endif