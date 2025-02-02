#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

/*  in 1bpp .BMP image, find occurence of another 1bpp .BMP image. If
 there is at least one, set x and y to coordinates of the upper left corner of
 any one of the occurences and return 0. If there is none, return 1. */
int32_t findimg(void *img, uint32_t width, uint32_t height, uint32_t stride,
                void* to_find, uint32_t to_find_width, uint32_t to_find_height, uint32_t to_find_stride,
                uint32_t *x, uint32_t *y);

void *load_bmp(FILE *file, uint32_t *width, uint32_t *height, uint32_t *stride) {

    if (fseek(file, 18, SEEK_SET) != 0) {
        perror("fseek failed while seeking width and height");
        return NULL;
    }

    if (fread(width, sizeof(uint32_t), 1, file) != 1) {
        perror("fread failed while reading width");
        return NULL;
    }

    if (fread(height, sizeof(uint32_t), 1, file) != 1) {
        perror("fread failed while reading height");
        return NULL;
    }

    // Calculate stride
    int32_t raw_bytes = (*width + 7) / 8;
    uint32_t padding = (4 - (raw_bytes % 4)) % 4;
    *stride = raw_bytes + padding;

    // Allocate memory for img data
    void *img = malloc((*stride) * (*height));
    if (!img) {
        perror("Memory allocation failed for image data");
        return NULL;
    }

    // Read the pixel data offset from the BMP file header (byte 10)
    uint32_t data_offset;
    if (fseek(file, 10, SEEK_SET) != 0) {
        perror("fseek failed while seeking to pixel data offset");
        free(img);
        return NULL;
    }

    if (fread(&data_offset, sizeof(uint32_t), 1, file) != 1) {
        perror("fread failed while reading pixel data offset");
        free(img);
        return NULL;
    }

    // Seek to the start of the bitmap data
    if (fseek(file, data_offset, SEEK_SET) != 0) {
        perror("fseek failed while seeking to pixel data");
        free(img);
        return NULL;
    }

    // Read the bitmap into the allocated memory
    size_t items_read = fread(img, (*stride), (*height), file);
    if (items_read != (*height)) {
        perror("fread failed while reading pixel data");
        free(img);
        return NULL;
    }

    return img;
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage: %s <img_file> <to_find_file>\n", argv[0]);
        return 1;
    }

    // Load main image
    FILE *img_file = fopen(argv[1], "rb");
    if (!img_file) {
        perror("Error opening main image file");
        return 1;
    }
    uint32_t width, height, stride;
    void *img = load_bmp(img_file, &width, &height, &stride);
    if (!img) {
        fclose(img_file);
        return 1;
    }
    fclose(img_file);

    // Load sub-image
    FILE *to_find_file = fopen(argv[2], "rb");
    if (!to_find_file) {
        perror("Error opening sub-image file");
        return 1;
    }
    uint32_t to_find_width, to_find_height, to_find_stride;
    void *to_find = load_bmp(to_find_file, &to_find_width, &to_find_height, &to_find_stride);
    if (!to_find) {
        fclose(to_find_file);
        free(img);
        return 1;
    }

    fclose(to_find_file);

    if(to_find_width > width || to_find_height > height) {
        printf("Sub image is larger than main image\n");
        free(img);
        free(to_find);
        return 1;
    }

    uint32_t x, y;
    if(findimg(img, width, height, stride, to_find, to_find_width, to_find_height, to_find_stride, &x, &y) == 0) {
        printf("Found at %d, %d\n", x, y);
    } else {
        printf("Not found\n");
    }
    printf("Main Image - Width: %u, Height: %u\n", width, height);
    printf("Sub Image - Width: %u, Height: %u\n", to_find_width, to_find_height);
    free(img);
    free(to_find);
    return 0;
}