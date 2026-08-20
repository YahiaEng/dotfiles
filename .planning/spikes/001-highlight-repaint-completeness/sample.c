// A comment, so Comment and @comment have something to colour.
#include <stdio.h>

typedef struct { int width; int height; } Rect;

static const int MAX_ITEMS = 42;   /* const -> readonly modifier */

int area(Rect r) {
    return r.width * r.height;
}

int main(void) {
    Rect box = { .width = 3, .height = 4 };
    const char *label = "hello";
    printf("%s %d %d\n", label, area(box), MAX_ITEMS);
    return 0;
}
